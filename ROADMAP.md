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
- [ ] M1.7 command-file arguments / `.KEY` differential runtime qualification
- [ ] broaden `CD` compatibility beyond the conservative standalone baseline

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

`tools/compat_bundle.py` packages the compatibility corpus, native and AmShell
runners, manifest, guest runner, 68000 binaries and instructions into
`build/m1.5-qualification/`.

The first visible FS-UAE/AmigaOS 2.04 qualification passed 10/10 cases on an
A500/68000 profile on 2026-09-14. The exact comparator verdict and raw guest
evidence are recorded in `docs/M1_5_QUALIFICATION.md` and
`docs/evidence/m1.5/`.

### M1.6 — native command-file execution baseline

A single non-option argument runs an AmigaDOS command file:

```text
AmShell scriptfile
```

AmShell delegates the file to native `EXECUTE` through the existing system-Shell backend. It does not parse the script itself, so established AmigaDOS command-file semantics remain owned by AmigaDOS.

`tools/script_compat_bundle.py` packages a native `EXECUTE` reference path and an AmShell candidate path for the same `basic.script`. `tools/script_compat_compare.py` compares captured output and RC, normalizing only the same documented volatile `Avail` counters used in M1.5. Host smoke tests are part of `make check`.

The M1.6 command-file differential qualification passed on visible
FS-UAE 3.2.35 with the A500/68000 Kickstart and Workbench 2.04 profile on
2026-09-14. Native `EXECUTE` and `AmShell basic.script` returned the same RC
and equivalent stable output. See `docs/M1_6_QUALIFICATION.md` for the raw
evidence and exact comparator verdict.

### M1.7 — native command-file arguments and `.KEY`

AmShell now accepts:

```text
AmShell scriptfile arg1 arg2 ...
```

AmShell only reconstructs the outer `EXECUTE` invocation, quoting each received argument using AmigaDOS escaping. `.KEY` parsing, substitution and failure behavior remain native AmigaDOS responsibilities. The seed differential fixture is `tests/compat/scripts/args.script`.

Runtime qualification remains pending. The qualification corpus must compare direct native `EXECUTE` with AmShell for positional, optional and keyword arguments, spaces/escaping and missing required arguments before M1.7 can be marked complete. `/N`, `/S`, defaults and `.BRA`/`.KET` should also be included before the final M1.7 verdict.

See `docs/M1_7_SCRIPT_ARGUMENTS.md`.

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
