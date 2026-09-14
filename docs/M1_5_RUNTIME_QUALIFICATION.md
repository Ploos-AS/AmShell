# M1.5 AmigaOS Runtime Differential Qualification

M1.5 turns the M1.4 differential harness into a reproducible qualification package for an actual AmigaOS 2.04+ guest.

## Goal

Run the same compatibility corpus through:

1. the native Amiga Shell, and
2. AmShell `-c`,

then compare deterministic stdout and return codes case-by-case.

## Prepare on the host

```sh
make check
make
make compat-bundle
```

The bundle is written to:

```text
build/m1.5-qualification/
```

If `build/AmShell` exists it is copied into the bundle. Otherwise the bundle remains valid, but the 68k binary must be added before guest execution.

## Run in FS-UAE / AmigaOS

Copy the complete bundle into the Amiga guest. Use an AmigaOS 2.04+ environment suitable for the 68000 baseline.

From the bundle directory run:

```text
Execute run-qualification.script
```

The guest writes observations to:

```text
T:AmShellCompat/
```

Copy that complete directory back to the host.

## Compare on the host

```sh
python3 tools/compat_compare.py RESULTS_DIR \
  --manifest build/m1.5-qualification/compat/manifest.txt
```

Qualification is **PASS only when every case matches** and the comparator prints:

```text
RESULT: PASS
```

Any missing result, stdout difference, or RC difference is a FAIL and must be investigated rather than waived silently.

## Evidence to record

A completed qualification report should record:

- AmShell commit SHA
- compiler/toolchain version
- FS-UAE version
- CPU profile
- Kickstart version
- Workbench/AmigaOS version
- corpus case count
- comparator verdict
- any known/accepted differences, if such exceptions are ever introduced explicitly

## Current status

The reproducible M1.5 qualification bundle is implemented. Runtime PASS is **not** claimed until the bundle has actually been executed on AmigaOS/FS-UAE and its returned evidence has passed `compat_compare.py`.
