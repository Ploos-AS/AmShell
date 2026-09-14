# M1 Final Qualification

Status: **PENDING** until visible guest execution and recorded evidence exist.

## Purpose

M1 final qualification combines the already-qualified execution-core regressions with the deferred M1.7-M1.11 compatibility surface in one visible FS-UAE run.

Baseline:

- FS-UAE, visible run
- A500 / 68000
- Kickstart + Workbench 2.04
- no FPU requirement

## Build

```text
make clean
make check
make
make m1-final-bundle
```

The resulting package is:

```text
build/m1-final-qualification/
```

## Guest run

Copy the complete package to an Amiga filesystem, make the package directory current, then run:

```text
Execute run-m1-final.script
```

The runner executes:

1. M1.5 ordinary-command differential regression
2. M1.6 native command-file regression
3. M1.7/M1.9 command-file arguments and extended `.KEY` surface
4. M1.11 native bare-name implied-CD precedence probe

The M1.8/M1.10 session semantics remain represented by the current AmShell binary and the M1.11 decision point. Patterned `CD` and path-like implied CD must be checked during the same visible session before a final verdict is recorded.

## Evidence

Preserve at minimum:

- `T:AmShellCompat/`
- `T:AmShellM16/`
- `T:AmShellM17/`
- `m1.11/native-*.out`
- `m1.11/native-*.rc`
- `m1.11/native-*.cwd`

Run the existing host comparators for M1.5, M1.6 and M1.7/M1.9.

## Bare-name implied CD

M1.11 intentionally records native stdout, RC and resulting current directory for:

- bare directory only
- bare command only
- command/directory name collision
- path-like directory

Do not implement or claim bare-name implied-CD precedence from assumptions. The native AmigaOS 2.04 result is authoritative.

If the native probe shows that AmShell must change, implement the change and rerun the entire M1 final bundle before declaring M1 complete.

## PASS rule

M1 may only be marked PASS when:

- all automated differential comparators pass,
- session-state behavior matches the native Shell for the claimed surface,
- M1.11 precedence has been resolved from guest evidence,
- any required code change has been followed by a complete rerun,
- the final evidence is recorded in the repository.

Building the bundle or passing host CI is **not** a runtime qualification.
