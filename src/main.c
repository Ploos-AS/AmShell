/*
 * AmShell - modern interactive shell for classic AmigaOS.
 *
 * Compatibility rule: ordinary command text is handed to the system Shell
 * for AmigaDOS parsing/execution.  AmShell must not reinterpret established
 * syntax while the compatible execution core is being built.
 */

#include <dos/dos.h>
#include <stdio.h>
#include <string.h>

#include "exec.h"

#define AMSHELL_VERSION "0.1.0-m1.1"

static void print_usage(const char *program)
{
    printf("Usage: %s [--version] [--help] [-c \"command\"]\n", program);
}

int main(int argc, char **argv)
{
    long rc;

    if (argc == 1) {
        puts("AmShell " AMSHELL_VERSION);
        puts("M1.1 compatible execution core; interactive mode follows later.");
        return RETURN_OK;
    }

    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        puts("AmShell " AMSHELL_VERSION);
        return RETURN_OK;
    }

    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        print_usage(argv[0]);
        return RETURN_OK;
    }

    if (argc == 3 && strcmp(argv[1], "-c") == 0) {
        rc = amshell_execute(argv[2]);
        if (rc < 0) {
            fputs("AmShell: unable to launch system Shell\n", stderr);
            return RETURN_FAIL;
        }
        return (int)rc;
    }

    fputs("AmShell: unsupported arguments\n", stderr);
    print_usage(argv[0]);
    return RETURN_FAIL;
}
