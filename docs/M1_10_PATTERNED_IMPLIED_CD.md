# M1.10 Patterned and Implied `CD` State Transfer

M1.10 closes most of the remaining interactive current-directory state gap without introducing an AmShell pattern parser.

## Explicit patterned `CD`

The original Shell supports patterns in `CD`, for example:

```text
CD SYS:Li#?
```

AmShell now resolves explicit `CD` patterns with the native V36+ dos.library directory-scanning API:

- `MatchFirst()`
- `MatchNext()`
- `MatchEnd()`

The matcher is allowed to interpret AmigaDOS pattern syntax. AmShell does not reimplement `#?`, `?`, alternation, negation, classes, or related semantics.

Only directory matches count. Exactly one matching directory is required before AmShell updates its own process current directory with `CurrentDir()`. If matching fails, is ambiguous, is interrupted, or otherwise does not produce exactly one directory, the original `CD` command line is delegated unchanged to the native system Shell so diagnostics and RC remain native.

This follows the documented Shell behavior that patterned `CD` succeeds for one matching directory and reports an error when more than one directory matches.

## Exact `CD`

Exact paths continue to use `Lock()` and `CurrentDir()`. M1.10 additionally verifies with `Examine()` that the lock is a directory before installing it as the process current directory. Invalid or non-directory targets are delegated to the native Shell for diagnostics and RC.

Quoted exact paths remain supported by the conservative outer decoder introduced in M1.8.

## Path-like implied `CD`

The Shell also supports implied `CD`, where the user omits the `CD` command. M1.10 transfers state directly for path-like standalone tokens containing `:` or `/`, including forms such as:

```text
SYS:Tools
/
//
:
```

The target must resolve through `Lock()` to a directory. Pattern syntax is not accepted for implied `CD`, matching the documented Shell restriction that patterns require explicit `CD`.

## Deferred bare-name implied `CD`

A standalone bare directory name such as:

```text
Tools
```

can also be an implied `CD` in the original Shell. AmShell deliberately continues to delegate this form for now because command lookup and directory-name precedence must be qualified before intercepting it safely. A directory and an executable may legally share a candidate command name, and compatibility takes priority over convenience.

The combined M1 final qualification must therefore include explicit patterned `CD`, path-like implied `CD`, and command-vs-directory precedence cases before the remaining bare-name implied surface can be declared equivalent.

## Runtime status

Implementation and host/CI structural checks do not constitute runtime qualification. M1.10 runtime execution remains deferred to the combined visible FS-UAE / AmigaOS 2.04 M1 final qualification.
