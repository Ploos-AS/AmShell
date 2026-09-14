# M1.6 Command-File Execution

M1.6 adds basic AmigaDOS command-file execution without introducing an AmShell script language.

## Interface

A single non-option argument is treated as an AmigaDOS command file:

```text
AmShell scriptfile
```

AmShell delegates execution to the native AmigaDOS `EXECUTE` command through the existing system-Shell backend. The script is therefore interpreted by AmigaDOS, not by AmShell.

## Compatibility rationale

`EXECUTE` is the established AmigaDOS mechanism for command files. It provides native script semantics, including dot commands and argument substitution, and executes script lines as Shell commands.

AmShell deliberately does **not**:

- parse command-file lines itself;
- invent a new script syntax;
- translate scripts to POSIX/Bash syntax;
- reinterpret AmigaDOS quoting, redirection, pipes, `FAILAT`, or script directives.

The command-file path is quoted before it is passed to `EXECUTE`, including AmigaDOS quote escaping for a literal quote in a path.

## M1.6 scope

The first implementation covers a single command-file path without script arguments. This is intentionally narrow. Argument-bearing `EXECUTE` semantics (`.KEY`, keyword arguments, defaults and substitutions) require their own differential runtime qualification before AmShell exposes them through its command-line interface.

The baseline fixture is:

```text
tests/compat/scripts/basic.script
```

## Qualification status

M1.6 implementation and host repository checks may pass independently of runtime qualification. A native-vs-AmShell command-file differential run on AmigaOS/FS-UAE is still required before claiming full M1.6 runtime PASS.
