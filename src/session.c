/*
 * AmShell interactive session state.
 *
 * Ordinary command text remains opaque and is delegated to the system Shell.
 * Only state changes that must affect AmShell's own process are intercepted.
 */

#include <ctype.h>
#include <dos/dos.h>
#include <dos/dosasl.h>
#include <exec/memory.h>
#include <exec/tasks.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <stdio.h>
#include <string.h>

#include "exec.h"
#include "session.h"

#define AMSHELL_CD_PATH_MAX 1024

static int is_space_char(char c)
{
    return c == ' ' || c == '\t';
}

static int ascii_equal_ci(const char *a, const char *b)
{
    while (*a != '\0' && *b != '\0') {
        if (toupper((unsigned char)*a) != toupper((unsigned char)*b)) {
            return 0;
        }
        ++a;
        ++b;
    }

    return *a == '\0' && *b == '\0';
}

static int is_cd_prefix(const char *line)
{
    if (line == 0) {
        return 0;
    }

    return toupper((unsigned char)line[0]) == 'C' &&
           toupper((unsigned char)line[1]) == 'D' &&
           (line[2] == '\0' || is_space_char(line[2]));
}

static int contains_compound_shell_syntax(const char *text)
{
    const char *p;

    for (p = text; *p != '\0'; ++p) {
        if (*p == ';' || *p == '<' || *p == '>') {
            return 1;
        }
    }

    return 0;
}

static int contains_pattern_syntax(const char *text)
{
    const char *p;

    for (p = text; *p != '\0'; ++p) {
        switch (*p) {
        case '#':
        case '?':
        case '%':
        case '~':
        case '(':
        case ')':
        case '|':
        case '[':
        case ']':
        case '*':
            return 1;
        default:
            break;
        }
    }

    return 0;
}

/*
 * Decode one standalone CD argument without interpreting AmigaDOS patterns.
 * Quoting is removed only so Lock()/MatchFirst() receive the same logical
 * path value. Pattern interpretation remains entirely inside dos.library.
 */
static int parse_cd_argument(
    const char *text,
    char *path,
    size_t path_size,
    int *is_pattern
)
{
    const char *start;
    const char *end;
    size_t length;

    while (is_space_char(*text)) {
        ++text;
    }

    if (*text == '\0') {
        return 0;
    }

    if (*text == '"') {
        size_t used = 0;
        ++text;

        while (*text != '\0' && *text != '"') {
            char ch = *text++;

            if (ch == '*') {
                if (*text != '"' && *text != '*') {
                    return 0;
                }
                ch = *text++;
            }

            if (used + 1 >= path_size) {
                return 0;
            }
            path[used++] = ch;
        }

        if (*text != '"') {
            return 0;
        }
        ++text;

        while (is_space_char(*text)) {
            ++text;
        }
        if (*text != '\0') {
            return 0;
        }

        path[used] = '\0';
        if (used == 0 || contains_compound_shell_syntax(path)) {
            return 0;
        }
        *is_pattern = contains_pattern_syntax(path);
        return 1;
    }

    start = text;
    end = text + strlen(text);
    while (end > start && is_space_char(end[-1])) {
        --end;
    }

    if (end == start) {
        return 0;
    }

    length = (size_t)(end - start);
    if (length >= path_size) {
        return 0;
    }

    memcpy(path, start, length);
    path[length] = '\0';

    if (strchr(path, '"') != 0 || contains_compound_shell_syntax(path)) {
        return 0;
    }

    /* Unquoted whitespace would mean more than one Shell argument. */
    for (start = path; *start != '\0'; ++start) {
        if (is_space_char(*start)) {
            return 0;
        }
    }

    *is_pattern = contains_pattern_syntax(path);
    return 1;
}

static int lock_is_directory(BPTR lock)
{
    struct FileInfoBlock fib;

    if (lock == 0 || !Examine(lock, &fib)) {
        return 0;
    }

    return fib.fib_DirEntryType > 0;
}

static long install_current_dir(BPTR lock)
{
    BPTR old_lock = CurrentDir(lock);

    if (old_lock != 0) {
        UnLock(old_lock);
    }

    return RETURN_OK;
}

/*
 * Resolve explicit CD patterns with the native V36+ matcher. This mirrors the
 * Shell rule that exactly one matching directory is required. When native
 * matching cannot produce one unambiguous directory, the original command is
 * delegated so AmigaDOS remains responsible for diagnostics and RC values.
 */
static long execute_pattern_cd(const char *line, const char *pattern)
{
    struct AnchorPath *anchor;
    size_t anchor_size = sizeof(struct AnchorPath) + AMSHELL_CD_PATH_MAX;
    char matched_path[AMSHELL_CD_PATH_MAX];
    long error;
    int directory_matches = 0;

    anchor = (struct AnchorPath *)AllocMem(anchor_size, MEMF_CLEAR);
    if (anchor == 0) {
        return amshell_execute(line);
    }

    anchor->ap_Strlen = AMSHELL_CD_PATH_MAX;
    anchor->ap_BreakBits = SIGBREAKF_CTRL_C;
    anchor->ap_FoundBreak = 0;
    anchor->ap_Flags = 0;

    error = MatchFirst((STRPTR)pattern, anchor);
    while (error == 0) {
        if (anchor->ap_Info.fib_DirEntryType > 0) {
            ++directory_matches;
            if (directory_matches == 1) {
                strncpy(
                    matched_path,
                    (const char *)anchor->ap_Buf,
                    sizeof(matched_path) - 1
                );
                matched_path[sizeof(matched_path) - 1] = '\0';
            }
        }
        error = MatchNext(anchor);
    }

    MatchEnd(anchor);
    FreeMem(anchor, anchor_size);

    if (error != ERROR_NO_MORE_ENTRIES || directory_matches != 1) {
        return amshell_execute(line);
    }

    {
        BPTR lock = Lock((STRPTR)matched_path, ACCESS_READ);
        if (lock == 0 || !lock_is_directory(lock)) {
            if (lock != 0) {
                UnLock(lock);
            }
            return amshell_execute(line);
        }
        return install_current_dir(lock);
    }
}

static long execute_persistent_cd(const char *line)
{
    const char *argument = line + 2;
    char path[AMSHELL_CD_PATH_MAX];
    int is_pattern = 0;
    BPTR lock;

    while (is_space_char(*argument)) {
        ++argument;
    }

    if (*argument == '\0') {
        /* Let the native Shell format the current-directory display. */
        return amshell_execute("CD");
    }

    if (!parse_cd_argument(argument, path, sizeof(path), &is_pattern)) {
        return amshell_execute(line);
    }

    if (is_pattern) {
        return execute_pattern_cd(line, path);
    }

    lock = Lock((STRPTR)path, ACCESS_READ);
    if (lock == 0 || !lock_is_directory(lock)) {
        if (lock != 0) {
            UnLock(lock);
        }
        /* Preserve native diagnostics and RC for invalid exact targets. */
        return amshell_execute(line);
    }

    return install_current_dir(lock);
}

/*
 * Implied CD is safe to transfer directly for unambiguous path-like tokens.
 * Bare directory names remain delegated until command-vs-directory precedence
 * is differentially qualified against the original Shell.
 */
static int try_pathlike_implied_cd(const char *line, long *result)
{
    char path[AMSHELL_CD_PATH_MAX];
    int is_pattern = 0;
    BPTR lock;

    if (line == 0 || (strchr(line, ':') == 0 && strchr(line, '/') == 0)) {
        return 0;
    }

    if (!parse_cd_argument(line, path, sizeof(path), &is_pattern) || is_pattern) {
        return 0;
    }

    lock = Lock((STRPTR)path, ACCESS_READ);
    if (lock == 0 || !lock_is_directory(lock)) {
        if (lock != 0) {
            UnLock(lock);
        }
        return 0;
    }

    *result = install_current_dir(lock);
    return 1;
}

int amshell_session_should_exit(const char *line)
{
    char command[16];
    size_t used = 0;

    if (line == 0) {
        return 0;
    }

    while (is_space_char(*line)) {
        ++line;
    }

    while (*line != '\0' && !is_space_char(*line)) {
        if (used + 1 >= sizeof(command)) {
            return 0;
        }
        command[used++] = *line++;
    }
    command[used] = '\0';

    while (is_space_char(*line)) {
        ++line;
    }
    if (*line != '\0') {
        return 0;
    }

    return ascii_equal_ci(command, "ENDCLI") ||
           ascii_equal_ci(command, "ENDSHELL");
}

long amshell_session_execute(const char *line)
{
    long implied_result;

    if (is_cd_prefix(line)) {
        return execute_persistent_cd(line);
    }

    if (try_pathlike_implied_cd(line, &implied_result)) {
        return implied_result;
    }

    return amshell_execute(line);
}
