/*
 * AmShell - modern interactive shell for classic AmigaOS.
 *
 * M0.1 deliberately contains no enhanced shell syntax.  The execution
 * core will be introduced in M1 under the compatibility contract.
 */

#include <stdio.h>
#include <string.h>

#define AMSHELL_VERSION "0.0.1-m0.1"

static void print_usage(const char *program)
{
    printf("Usage: %s [--version] [--help]\n", program);
}

int main(int argc, char **argv)
{
    if (argc == 1) {
        puts("AmShell " AMSHELL_VERSION);
        puts("M0.1 foundation build; compatible execution core arrives in M1.");
        return 0;
    }

    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        puts("AmShell " AMSHELL_VERSION);
        return 0;
    }

    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        print_usage(argv[0]);
        return 0;
    }

    fprintf(stderr, "AmShell: unsupported M0.1 argument\n");
    print_usage(argv[0]);
    return 20;
}
