# M1.4 Differential Compatibility Qualification

M1.4 adds an automated differential harness for comparing the original Amiga Shell with AmShell.

## What is automated now

Host-side automation can:

1. read `tests/compat/cases.txt`;
2. generate exact native command files;
3. generate a native-Shell runner;
4. generate an AmShell `-c` runner;
5. compare collected stdout and return-code files;
6. fail when output, RC, or required result files differ.

Run:

```sh
make check
make compat-prepare
```

The prepared guest files are written below `build/compat/`.

## Guest runtime procedure

Copy the complete prepared `build/compat/` directory to the Amiga guest, preserving its `cases/` subdirectory, and ensure the current directory is that directory.

Place the M1.4 `AmShell` binary on the command path or adjust `--amshell` when preparing the scripts.

On the target AmigaOS environment run:

```text
Execute run-native.script
Execute run-amshell.script
```

Both runners write their observations to `T:AmShellCompat/`.

Copy the contents of `T:AmShellCompat/` back to the host together with `manifest.txt`, then run:

```sh
python3 tools/compat_compare.py RESULTS_DIR --manifest build/compat/manifest.txt
```

A qualification PASS requires every collected case to have equivalent output and RC.

## Compatibility integrity

The native reference path uses one generated command file per testcase. This prevents the harness from appending capture syntax directly to the command under test, which would alter cases that already contain redirection.

The AmShell path receives the original command text through its `-c` interface. Harness redirection is outside that command text.

## Qualification status

The differential harness is implemented and host-smoke-tested in M1.4. This document does **not** claim that an AmigaOS runtime qualification has already passed. Runtime evidence must be produced on a real/emulated target before such a claim is made.

## Current comparison scope

M1.4 compares deterministic stdout and numeric RC. Later milestones may additionally compare stderr, filesystem effects, current-directory state, environment/local variables, and script-level state when required by a testcase.
