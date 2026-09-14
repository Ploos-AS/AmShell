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
- [ ] basic command-file execution
- [x] seed original-Shell differential compatibility corpus
- [ ] automated runtime differential comparison against original Shell
- [ ] broaden `CD` compatibility beyond the conservative standalone baseline

### M1.1 — non-interactive execution baseline

Implemented with `dos.library/SystemTagList()` (V36+) so established AmigaDOS parsing remains owned by the system Shell. AmShell does not introduce an independent parser for ordinary command text.

### M1.2 — interactive loop baseline

AmShell provides a minimal interactive read/execute loop. Ordinary command lines remain opaque to AmShell and are delegated to the system Shell. The session records the last return code.

### M1.3 — persistent directory baseline and compatibility corpus

Simple standalone `CD path` now updates AmShell's own process current directory using AmigaDOS `Lock()`/`CurrentDir()`, so later child Shell invocations inherit it.

This is deliberately conservative. Quoted or compound `CD` command lines containing shell syntax remain untouched and are delegated to the native Shell. Full original-Shell `CD` syntax equivalence is not claimed yet.

`tests/compat/cases.txt` seeds the differential compatibility corpus for native Shell versus AmShell runtime comparison.

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
