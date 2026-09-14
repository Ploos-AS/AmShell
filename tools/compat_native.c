/*
 * Native Amiga Shell capture launcher for differential qualification.
 *
 * The command file is read as opaque text and handed to SystemTagList().
 * Parsing and execution remain entirely owned by the original Amiga Shell.
 */

#include <exec/types.h>
#include <dos/dos.h>
#include <dos/dostags.h>
#include <proto/dos.h>
#include <utility/tagitem.h>

#define COMMAND_MAX 1024

static int fail(const char *message)
{
    PutStr((STRPTR)message);
    return RETURN_FAIL;
}

int main(int argc, char **argv)
{
    char command[COMMAND_MAX];
    char extra;
    BPTR input;
    BPTR output;
    LONG length;
    LONG rc;
    struct TagItem tags[3];

    if (argc != 3) {
        return fail("CompatNative: expected COMMAND_FILE OUTPUT_FILE\n");
    }

    input = Open((STRPTR)argv[1], MODE_OLDFILE);
    if (input == 0) {
        return fail("CompatNative: cannot open command file\n");
    }

    length = Read(input, command, COMMAND_MAX - 1);
    if (length < 0 || (length == COMMAND_MAX - 1 && Read(input, &extra, 1) != 0)) {
        Close(input);
        return fail("CompatNative: cannot read command file\n");
    }
    Close(input);

    while (length > 0 && (command[length - 1] == '\n' || command[length - 1] == '\r')) {
        --length;
    }
    command[length] = '\0';
    if (length == 0) {
        return fail("CompatNative: empty command file\n");
    }

    output = Open((STRPTR)argv[2], MODE_NEWFILE);
    if (output == 0) {
        return fail("CompatNative: cannot open output file\n");
    }

    tags[0].ti_Tag = SYS_Output;
    tags[0].ti_Data = (ULONG)output;
    tags[1].ti_Tag = SYS_UserShell;
    tags[1].ti_Data = TRUE;
    tags[2].ti_Tag = TAG_DONE;
    tags[2].ti_Data = 0;

    rc = SystemTagList((STRPTR)command, tags);
    Close(output);

    if (rc < 0) {
        return fail("CompatNative: native Shell launch failed\n");
    }
    return (int)rc;
}
