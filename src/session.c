/*
 * AmShell interactive session state.
 *
 * Ordinary command text remains opaque and is delegated to the system Shell.
 * Only state changes that must affect AmShell's own process are intercepted.
 */

#include <ctype.h>
#include <dos/dos.h>
#include <proto/dos.h>
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

static int contains_shell_or_pattern_syntax(const char *text)
{
    const char *p;

    for (p = text; *p != '\0'; ++p) {
        switch (*p) {
        case ';':
        case '|':
        case '<':
        case '>':
        case '#':
        case '?':
        case '%':
        case '~':
        case '(':
        case ')':
            return 1;
        default:
            break;
        }
    }

    return 0;
}

/*
 * Parse only an exact CD path whose meaning is unambiguous without
 * reimplementing AmigaDOS pattern parsing. Returns 1 on success, 0 when the
 * line must be delegated unchanged to the native Shell.
 */
static int parse_exact_cd_path(const char *text, char *path, size_t path_size)
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
        return used != 0 && !contains_shell_or_pattern_syntax(path);
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

    if (strchr(path, '"') != 0 || contains_shell_or_pattern_syntax(path)) {
        return 0;
    }

    return 1;
}

static long execute_persistent_cd(const char *line)
{
    const char *argument = line + 2;
    char path[AMSHELL_CD_PATH_MAX];
    BPTR lock;
    BPTR old_lock;

    while (is_space_char(*argument)) {
        ++argument;
    }

    if (*argument == '\0') {
        /* Let the native Shell format the current-directory display. */
        return amshell_execute("CD");
    }

    if (!parse_exact_cd_path(argument, path, sizeof(path))) {
        /* Patterns, compound syntax and uncertain quoting stay native. */
        return amshell_execute(line);
    }

    lock = Lock((STRPTR)path, ACCESS_READ);
    if (lock == 0) {
        /* Preserve native diagnostics and RC for an invalid exact target. */
        return amshell_execute(line);
    }

    old_lock = CurrentDir(lock);
    if (old_lock != 0) {
        UnLock(old_lock);
    }

    return RETURN_OK;
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
    if (is_cd_prefix(line)) {
        return execute_persistent_cd(line);
    }

    return amshell_execute(line);
}
