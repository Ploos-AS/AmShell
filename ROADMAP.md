# AmShell Roadmap

## M0 — Foundation

- [x] Define project identity and target platform.
- [x] Make original Amiga Shell compatibility a first-class requirement.
- [x] Define compatibility contract.
- [x] Establish initial architecture and milestone plan.
- [x] Add buildable 68000 skeleton.
- [x] Add host-side repository checks.
- [x] Add CI for repository checks.

## M1 — Compatible execution core

Goal: execute ordinary AmigaDOS command lines without changing their established meaning.

- [x] command input loop
- [x] AmigaDOS execution backend
- [x] command/argument forwarding through `-c`
- [x] persistent current-directory baseline for simple standalone `CD path`
- [x] return-code propagation for executed commands
- [x] interactive session retains last command RC
- [x] non-interactive `-c` execution
- [x] basic command-file execution through native `EXECUTE`
- [x] seed original-Shell differential compatibility corpus
- [x] automated differential harness and result comparator
- [x] reproducible M1.5 AmigaOS/FS-UAE qualification bundle
- [x] run and record first AmigaOS/FS-UAE differential qualification
- [x] reproducible M1.6 command-file qualification bundle and comparator
- [x] M1.6 command-file runtime differential qualification on visible FS-UAE
- [x] M1.7 command-file argument forwarding implementation and seed `.KEY` fixture
- [x] reproducible M1.7 script-argument qualification bundle and comparator
- [x] defer M1.7 runtime execution to combined M1 final qualification
- [x] M1.9 broaden script fixtures with `/N`, `/S`, defaults and `.BRA`/`.KET`
- [x] M1.8 native `ENDCLI`/`ENDSHELL` termination semantics
- [x] M1.8 persistent exact quoted-path `CD` baseline
- [x] M1.10 explicit patterned `CD` state transfer via native V36 matcher
- [x] M1.10 path-like implied `CD` state transfer
- [ ] qualify bare-name implied `CD` command-vs-directory precedence
- [ ] combined M1 final visible-FS-UAE differential qualification

### M1.1 — non-interactive execution baseline

Implemented with `dos.library/SystemTagList()` (V36+) so established AmigaDOS parsing remains owned by the system Shell. AmShell does not introduce an independent parser for ordinary command text.

### M1.2 — interactive loop baseline

AmShell provides a minimal interactive read/execute loop. Ordinary command lines remain opaque to AmShell and are delegated to the system Shell. The session records the last return code.

### M1.3 — persistent directory baseline and compatibility corpus

Simple standalone `CD path` updates AmShell's own process current directory using AmigaDOS `Lock()`/`CurrentDir()`, so later child Shell invocations inherit it.

This is deliberately conservative. Quoted or compound `CD` command lines containing shell syntax remain untouched and are delegated to the native Shell. Full original-Shell `CD` syntax equivalence is not claimed yet.

`tests/compat/cases.txt` seeds the differential compatibility corpus for native Shell versus AmShell runtime comparison.

### M1.4 — automated differential harness

`tools/compat_prepare.py` generates native-reference and AmShell-candidate guest scripts from the same canonical corpus. Native commands are preserved in individual command files so capture logic does not alter the tested command text.

`tools/compat_compare.py` compares collected deterministic stdout and RC observations and emits an explicit PASS/FAIL verdict. Host-side smoke tests cover preparation, equivalence and deliberate mismatch detection.

### M1.5 — reproducible runtime qualification package

`tools/compat_bundle.py` packages the compatibility corpus, native and AmShell runners, manifest, guest runner, 68000 binaries and instructions into `build/m1.5-qualification/`.

The first visible FS-UAE/AmigaOS 2.04 qualification passed 10/10 cases on an A500/68000 profile on 2026-09-14. The exact comparator verdict and raw guest evidence are recorded in `docs/M1_5_QUALIFICATION.md` and `docs/evidence/m1.5/`.

### M1.6 — native command-file execution baseline

A single non-option argument runs an AmigaDOS command file:

```text
AmShell scriptfile
```

AmShell delegates the file to native `EXECUTE` through the existing system-Shell backend. It does not parse the script itself, so established AmigaDOS command-file semantics remain owned by AmigaDOS.

`tools/script_compat_bundle.py` packages a native `EXECUTE` reference path and an AmShell candidate path for the same `basic.script`. `tools/script_compat_compare.py` compares captured output and RC, normalizing only the same documented volatile `Avail` counters used in M1.5. Host smoke tests are part of `make check`.

The M1.6 command-file differential qualification passed on visible FS-UAE 3.2.35 with the A500/68000 Kickstart and Workbench 2.04 profile on 2026-09-14. Native `EXECUTE` and `AmShell basic.script` returned the same RC and equivalent stable output. See `docs/M1_6_QUALIFICATION.md` for the raw evidence and exact comparator verdict.

### M1.7 — native command-file arguments and `.KEY`

AmShell accepts:

```text
AmShell scriptfile arg1 arg2 ...
```

AmShell only reconstructs the outer `EXECUTE` invocation, quoting each received argument using AmigaDOS escaping. `.KEY` parsing, substitution and failure behavior remain native AmigaDOS responsibilities.

`tests/compat/script_args_cases.tsv` and `tools/script_args_compat_bundle.py` package direct native `EXECUTE` and AmShell candidate runs. `tools/script_args_compat_compare.py` requires identical captured output and RC. Runtime execution remains deliberately deferred to the combined M1 final qualification.

### M1.8 — interactive session compatibility

AmShell follows the original Shell's termination commands: standalone `ENDCLI` and `ENDSHELL` terminate the AmShell interactive loop. The previous special handling of `EXIT` was removed so `EXIT` is ordinary delegated command text.

Persistent exact `CD` handling accepts quoted paths, trims surrounding whitespace and supports paths that `Lock()` resolves, including `/`, `//`, `:` and device/assign paths. Invalid and non-directory targets are delegated to native Shell diagnostics.

### M1.9 — extended native script surface

The deferred script-argument qualification corpus now includes native AmigaDOS behavior for `/N`, `/S`, invalid numeric input, `.DEF`, inline defaults, and `.BRA`/`.KET`. The same multi-fixture harness compares native `EXECUTE` with AmShell on stdout and RC without replacing native script semantics.

See `docs/M1_9_EXTENDED_SCRIPT_SURFACE.md`.

### M1.10 — patterned and implied `CD`

Explicit patterned `CD` now uses native V36+ `MatchFirst()` / `MatchNext()` / `MatchEnd()` rather than an AmShell wildcard parser. Only directory matches count, and exactly one directory must match before AmShell installs the resolved lock as its own current directory. Ambiguous, failed or interrupted matches are delegated back to the original system Shell for native diagnostics and RC.

Path-like implied `CD` is also transferred into AmShell state when a standalone token containing `:` or `/` resolves to a directory. This covers forms such as `SYS:Tools`, `/`, `//` and `:`. Pattern matching remains disallowed for implied `CD`, matching native Shell documentation.

Bare-name implied `CD` such as `Tools` is still deferred because command lookup versus directory-name precedence must be differentially qualified before AmShell can intercept it without compatibility risk.

See `docs/M1_10_PATTERNED_IMPLIED_CD.md`.

### M1 final qualification

Before M1 is declared complete, run one combined visible FS-UAE qualification on the A500/68000 + AmigaOS 2.04 baseline. It must include regression of already-qualified M1.5/M1.6 behavior plus deferred M1.7/M1.9 script arguments, M1.8 termination/state cases, M1.10 patterned/path-like implied `CD`, and bare-name implied-CD precedence. Any unqualified behavior remains explicitly pending until that run produces recorded evidence.

No enhanced syntax is allowed to compromise M1 compatibility.

## M2 — Interactive line editor and history

- cursor movement
- Home/End, Insert/Delete and useful control-key editing
- in-memory history
- Up/Down history navigation
- persistent history
- incremental history search

These features operate on the interactive input buffer and do not redefine AmigaDOS command syntax.

## M3 — Completion

- command completion
- file and directory completion
- device/volume/assign completion
- case-insensitive matching appropriate to AmigaDOS
- multiple-candidate display
- extensible completion-provider interface

## M4 — Interactive conveniences

- aliases with compatibility-safe design
- configurable prompt
- configuration file
- enhanced status information

Potential syntax conflicts require opt-in or an unambiguous mechanism.

## M5 — ARexx

- `AMSHELL` public ARexx port
- command execution
- state/query API
- history and current-directory queries
- completion providers
- prompt/pre-command/post-command hooks
- external extension support

## M6 — Compatibility qualification

- broaden differential test corpus
- AmigaOS 2.04 qualification
- later classic AmigaOS qualification
- 68000 baseline qualification
- existing script regression suite
- document known behavioural differences

## M7 — v0.1.0

First release once the interactive feature set and compatibility corpus are both sufficiently mature. Compatibility takes priority over release speed.

## Later candidates

- richer completion metadata
- optional job-management improvements
- programmable interactive hooks
- integrations with other Amiga tools

Full Bash/POSIX emulation is explicitly not a near-term goal.
