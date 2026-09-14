# AmShell Architecture

## Design priorities

1. Original Amiga Shell compatibility.
2. Small footprint and 68000 suitability.
3. Clear separation between command semantics and interactive conveniences.
4. Testability.
5. Extensibility through ARexx without requiring a heavy plugin runtime.

## Proposed layers

### Input / line editor

Owns interactive editing, history navigation and completion. It produces a command line but should not reinterpret valid AmigaDOS syntax.

### Compatibility/execution core

Owns command submission, process context, return codes and interaction with AmigaDOS. This is the most compatibility-sensitive layer.

### History

Stores accepted interactive command lines. Persistence is optional/configurable and independent of command execution semantics.

### Completion

Examines the current input buffer and proposes edits before submission. Completion must never change a command after it has been submitted.

### Configuration

Controls interactive behaviour. Compatibility-affecting extensions must be explicit.

### ARexx service

Exposes AmShell state and operations through a public `AMSHELL` port. ARexx hooks/providers sit outside the compatibility core so they can be disabled without changing basic Shell behaviour.

## Testing model

AmShell should distinguish:

- host/static tests
- native Amiga build tests
- emulator runtime tests
- differential compatibility tests against the original Shell

The differential suite is particularly important: identical fixtures should be run in both environments and compare output, return codes, filesystem effects and relevant environment/process state where deterministic.
