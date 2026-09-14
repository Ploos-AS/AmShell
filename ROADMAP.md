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

- command input loop
- AmigaDOS execution backend
- command/argument forwarding
- current-directory handling
- return-code propagation
- non-interactive `-c` execution
- basic command-file execution
- initial original-Shell differential compatibility tests

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
