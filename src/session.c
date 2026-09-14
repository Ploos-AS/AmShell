/*
 * AmShell interactive session state.
 *
 * M1.3 keeps ordinary command text opaque and delegates it to the system
 * Shell.  The one stateful exception is a simple standalone CD command,
 * because a child Shell cannot change AmShell's process current directory.
 * Complex command lines containing shell syntax are still delegated unchanged.
 */

#include <ctype.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include <stdio.h>
#include <string.h>

#include "exec.h"
#include "session.h"

static int is_space_char(char c)
{
    return c == ' ' || c == '\t';
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

static int contains_shell_syntax(const char *text)
{
    const char *p;

    for (p = text; *p != '\0'; ++p) {
        if (*p == '"' || *p == ';' || *p == '|' || *p == '<' || *p == '>') {
            return 1;
        }
    }

    return 0;
}

static long execute_simple_cd(const char *line)
{
    const char *path = line + 2;
    BPTR lock;
    BPTR old_lock;

    while (is_space_char(*path)) {
        ++path;
    }

    if (*path == '\0') {
        /* Let the native Shell print the current directory exactly as it does. */
        return amshell_execute("CD");
    }

    if (contains_shell_syntax(path)) {
        return amshell_execute(line);
    }

    lock = Lock((STRPTR)path, ACCESS_READ);
    if (lock == 0) {
        /* Preserve native diagnostics and RC for invalid CD targets. */
        return amshell_execute(line);
    }

    old_lock = CurrentDir(lock);
    if (old_lock != 0) {
        UnLock(old_lock);
    }

    return RETURN_OK;
}

long amshell_session_execute(const char *line)
{
    if (is_cd_prefix(line)) {
        return execute_simple_cd(line);
    }

    return amshell_execute(line);
}
