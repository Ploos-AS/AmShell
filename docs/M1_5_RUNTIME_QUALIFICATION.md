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

The Makefile builds and bundles both the 68000 AmShell binary and the small
`CompatNative` reference-capture launcher. The launcher passes each unchanged
command file to the original Shell; it does not parse command text.

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

For `Avail`, the comparator retains the complete captured output but compares
only its stable structure, memory types and `Maximum` values. Its transient
`Available`, `In-Use` and `Largest` counters necessarily reflect the differing
launcher footprints and are explicitly normalized.

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

The first real runtime qualification passed 10/10 cases in visible FS-UAE on
2026-09-14 using an A500/68000 Kickstart and Workbench 2.04 environment. See
`docs/M1_5_QUALIFICATION.md` and `docs/evidence/m1.5/` for the exact verdict and
raw returned guest evidence.
