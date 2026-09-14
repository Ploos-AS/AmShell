/*
 * Compatible AmigaDOS execution backend.
 *
 * SystemTagList() is available from dos.library V36 (AmigaOS 2.0) and
 * delegates parsing and execution to the system Shell.  That is deliberate:
 * M1 must preserve established AmigaDOS syntax instead of reinterpreting it.
 */

#include <exec/types.h>
#include <dos/dos.h>
#include <dos/dostags.h>
#include <proto/dos.h>
#include <utility/tagitem.h>

#include "exec.h"

long amshell_execute(const char *command)
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
