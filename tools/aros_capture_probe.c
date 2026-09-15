#include <exec/types.h>
#include <dos/dos.h>
#include <dos/dostags.h>
#include <proto/dos.h>

static void write_probe_rc(const char *path, LONG rc)
{
    BPTR fh;
    char digit;

    fh = Open((STRPTR)path, MODE_NEWFILE);
    if (!fh) {
        return;
    }

    digit = (rc == RETURN_OK) ? '0' : '1';
    Write(fh, &digit, 1);
    Write(fh, (APTR)"\n", 1);
    Close(fh);
}

int main(void)
{
    BPTR direct;
    BPTR sysout;
    LONG rc;
    struct TagItem tags[4];
    static const char direct_text[] = "direct-dos-write\n";

    direct = Open((STRPTR)"RAM:amshell-probe-direct.txt", MODE_NEWFILE);
    if (direct) {
        Write(direct, (APTR)direct_text, sizeof(direct_text) - 1);
        Close(direct);
    }

    rc = SystemTagList((STRPTR)"Echo shell-redirection >RAM:amshell-probe-redir.txt", 0);
    write_probe_rc("RAM:amshell-probe-redir.rc", rc);

    sysout = Open((STRPTR)"RAM:amshell-probe-sysout.txt", MODE_NEWFILE);
    if (sysout) {
        tags[0].ti_Tag = SYS_Input;
        tags[0].ti_Data = (ULONG)Input();
        tags[1].ti_Tag = SYS_Output;
        tags[1].ti_Data = (ULONG)sysout;
        tags[2].ti_Tag = SYS_UserShell;
        tags[2].ti_Data = FALSE;
        tags[3].ti_Tag = TAG_DONE;
        tags[3].ti_Data = 0;
        rc = SystemTagList((STRPTR)"Echo systemtag-output", tags);
        Close(sysout);
        write_probe_rc("RAM:amshell-probe-sysout.rc", rc);
    }

    return RETURN_OK;
}
