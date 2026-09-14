# M1.3 compatibility baseline

M1.3 introduces persistent current-directory state for the interactive shell and seeds the first differential compatibility corpus.

## Current-directory policy

Ordinary command lines remain opaque to AmShell and are executed by the native AmigaDOS Shell through `SystemTagList()`.

A child Shell cannot change the parent AmShell process current directory, so M1.3 handles only a deliberately narrow form of stateful command itself:

- `CD path` where `path` is a simple unquoted standalone target

The implementation uses `Lock()` and `CurrentDir()` so subsequent commands inherit the changed directory.

AmShell does **not** claim full native `CD` syntax equivalence yet. If the text following `CD` contains quoting, command separators, pipes, or redirection, AmShell delegates the entire line unchanged to the native Shell rather than attempting to parse it.

This restriction is intentional. Compatibility takes priority over feature coverage.

## Differential corpus

`tests/compat/cases.txt` is the initial native-Shell comparison corpus. It includes ordinary commands, quoting, return-code-related behaviour, current-directory display, and redirection.

The corpus is structural in M1.3. Runtime automation that executes each case through both the original Shell and AmShell and compares observable results is the next compatibility step.

## Qualification status

M1.3 is ready for build/runtime qualification, but full original-Shell compatibility is not yet claimed.
