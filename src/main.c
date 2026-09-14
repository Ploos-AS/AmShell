/*
 * AmShell - modern interactive shell for classic AmigaOS.
 *
 * Compatibility rule: ordinary command text is handed to the system Shell
 * for AmigaDOS parsing/execution. AmShell only intercepts narrowly defined
 * session-state operations that cannot persist through a child Shell.
 */

#include <dos/dos.h>
#include <stdio.h>
#include <string.h>

#include "exec.h"
#include "session.h"

#define AMSHELL_VERSION "0.1.0-m1.6"
#define AMSHELL_LINE_MAX 1024

static void print_usage(const char *program)
{
    printf("Usage: %s [--version] [--help] [-c \"command\"] [command-file]\n", program);
}

static void trim_line_end(char *line)
{
    size_t len = strlen(line);

    while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) {
        line[--len] = '\0';
    }
}

static int interactive_loop(void)
{
    char line[AMSHELL_LINE_MAX];
    long last_rc = RETURN_OK;

    puts("AmShell " AMSHELL_VERSION);

    for (;;) {
        fputs("AmShell> ", stdout);
        fflush(stdout);

        if (fgets(line, sizeof(line), stdin) == 0) {
            putchar('\n');
            break;
        }

        trim_line_end(line);

        if (line[0] == '\0') {
            continue;
        }

        /* EXIT remains the only interactive control command. */
        if (strcmp(line, "exit") == 0 || strcmp(line, "EXIT") == 0) {
            break;
        }

        last_rc = amshell_session_execute(line);
        if (last_rc < 0) {
            fputs("AmShell: unable to launch system Shell\n", stderr);
            last_rc = RETURN_FAIL;
        }
    }

    return (int)last_rc;
}

static int normalize_result(long rc)
{
    if (rc < 0) {
        fputs("AmShell: unable to launch system Shell\n", stderr);
        return RETURN_FAIL;
    }
    return (int)rc;
}

int main(int argc, char **argv)
{
    if (argc == 1) {
        return interactive_loop();
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
        return normalize_result(amshell_execute(argv[2]));
    }

    if (argc == 2 && argv[1][0] != '-') {
        return normalize_result(amshell_execute_file(argv[1]));
    }

    fputs("AmShell: unsupported arguments\n", stderr);
    print_usage(argv[0]);
    return RETURN_FAIL;
}
