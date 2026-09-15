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
        /*
         * Pass the current process streams explicitly.  This preserves the
         * caller's redirection when SystemTagList() starts the system Shell.
         * Classic AmigaDOS normally inherits these streams; AROS' hosted CI
         * path does not do so reliably when the tags are omitted.
         */
        { SYS_Input, (ULONG)Input() },
        { SYS_Output, (ULONG)Output() },
        { SYS_UserShell, FALSE },
        { TAG_DONE, 0 }
    };

    if (command == 0 || *command == '\0') {
        return RETURN_OK;
    }

    return (long)SystemTagList((STRPTR)command, tags);
}

static int append_quoted_arg(char **outp, size_t *remainingp, const char *text)
{
    char *out = *outp;
    size_t remaining = *remainingp;
    const char *in;

    if (remaining <= 2) {
        return 0;
    }

    *out++ = '"';
    --remaining;

    for (in = text; *in != '\0'; ++in) {
        if (*in == '"' || *in == '*') {
            if (remaining <= 2) {
                return 0;
            }
            *out++ = '*';
            *out++ = *in;
            remaining -= 2;
        } else {
            if (remaining <= 1) {
                return 0;
            }
            *out++ = *in;
            --remaining;
        }
    }

    if (remaining <= 1) {
        return 0;
    }

    *out++ = '"';
    --remaining;
    *out = '\0';

    *outp = out;
    *remainingp = remaining;
    return 1;
}

long amshell_execute(const char *command)
{
    return run_system_shell(command);
}

long amshell_execute_file_args(const char *path, int argc, char **argv)
{
    char command[AMSHELL_EXEC_LINE_MAX];
    char *out;
    size_t remaining;
    int i;

    if (path == 0 || *path == '\0' || argc < 0) {
        return RETURN_FAIL;
    }

    /*
     * Command files remain native AmigaDOS scripts. Build only the outer
     * EXECUTE invocation; .KEY processing and substitution remain owned by
     * the native Shell/EXECUTE implementation.
     */
    strcpy(command, "Execute ");
    out = command + strlen(command);
    remaining = sizeof(command) - strlen(command);

    if (!append_quoted_arg(&out, &remaining, path)) {
        return RETURN_FAIL;
    }

    for (i = 0; i < argc; ++i) {
        if (remaining <= 1) {
            return RETURN_FAIL;
        }
        *out++ = ' ';
        --remaining;
        *out = '\0';

        if (!append_quoted_arg(&out, &remaining, argv[i])) {
            return RETURN_FAIL;
        }
    }

    return run_system_shell(command);
}

long amshell_execute_file(const char *path)
{
    return amshell_execute_file_args(path, 0, 0);
}
