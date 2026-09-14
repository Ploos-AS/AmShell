/*
 * Compatible AmigaDOS execution backend.
 *
 * SystemTagList() is available from dos.library V36 (AmigaOS 2.0) and
 * delegates parsing and execution to the system Shell. That is deliberate:
 * M1 must preserve established AmigaDOS syntax instead of reinterpreting it.
 */

#include <exec/types.h>
#include <dos/dos.h>
#include <dos/dostags.h>
#include <proto/dos.h>
#include <utility/tagitem.h>
#include <stdio.h>
#include <string.h>

#include "exec.h"

#define AMSHELL_EXEC_LINE_MAX 2048

static long run_system_shell(const char *command)
{
    struct TagItem tags[] = {
        { SYS_UserShell, FALSE },
        { TAG_DONE, 0 }
    };

    if (command == 0 || *command == '\0') {
        return RETURN_OK;
    }

    return (long)SystemTagList((STRPTR)command, tags);
}

long amshell_execute(const char *command)
{
    return run_system_shell(command);
}

long amshell_execute_file(const char *path)
{
    char command[AMSHELL_EXEC_LINE_MAX];
    char *out;
    const char *in;
    size_t remaining;

    if (path == 0 || *path == '\0') {
        return RETURN_FAIL;
    }

    /*
     * Command files remain native AmigaDOS scripts. We invoke C:Execute
     * rather than reading or parsing the file ourselves, preserving EXECUTE
     * semantics such as dot commands and parameter substitution.
     */
    strcpy(command, "Execute \"");
    out = command + strlen(command);
    remaining = sizeof(command) - strlen(command);

    for (in = path; *in != '\0'; ++in) {
        if (*in == '"') {
            if (remaining <= 2) {
                return RETURN_FAIL;
            }
            *out++ = '*';
            *out++ = '"';
            remaining -= 2;
        } else {
            if (remaining <= 1) {
                return RETURN_FAIL;
            }
            *out++ = *in;
            --remaining;
        }
    }

    if (remaining <= 2) {
        return RETURN_FAIL;
    }

    *out++ = '"';
    *out = '\0';

    return run_system_shell(command);
}
