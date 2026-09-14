# M1.6 FS-UAE / AmigaOS Command-File Qualification

## Verdict

**PASS — 2026-09-14.** The real M1.6 command-file differential qualification
completed in visible, windowed FS-UAE. Native AmigaDOS `EXECUTE` and
`AmShell basic.script` produced equivalent stable output and the same return
code for the identical command file.

Exact comparator verdict:

```text
RESULT: PASS (native EXECUTE and AmShell command-file behavior equivalent)
```

## Qualified environment

- FS-UAE: 3.2.35, normal visible 960 x 720 window (`fullscreen = 0`), not
  headless
- Machine profile: A500, PAL, 1024 KiB chip RAM, 4096 KiB fast RAM, no slow
  RAM and no floppy drive
- CPU: Motorola 68000, no FPU; guest `CPU` reported
  `System: 68000 (INST: NoCache)`
- Kickstart: AmigaOS 2.04, revision 37.175
- Workbench/AmigaOS: Workbench 2.04, revision 37.67
- Toolchain: Bebbo `m68k-amigaos-gcc (GCC) 6.5.0b 20260807212032`
- Build flags: `-Os -Wall -Wextra -Werror -m68000`
- AmShell source commit tested: `c27f0b672e8cc358bac40aca2f2b0f8dccc200df`
- AmShell SHA-256:
  `a4aed4c0054c9e0fda09e138c59519d86f7d97584a99e6c166d7527c2882baca`
- Fixture: `tests/compat/scripts/basic.script`
- Fixture SHA-256:
  `14607aa5cc8c0ef81974317ebead6665c9a2e16f5cc8f6cf73c3204f4211b285`
- Native RC: `0`
- AmShell RC: `0`

The runtime-tested source commit is the AmShell implementation used for the
binary. The qualification commit changes the host harness check, documentation
and evidence, but does not change AmShell execution or parsing semantics.

## Execution and comparison

The host completed `make clean`, `make check`, `make`, and
`make script-compat-bundle`. `file` identified both bundled programs as
AmigaOS loadseg()-able, and `m68k-amigaos-objdump -f` reported `m68k:68000`.
The bundled fixture was byte-for-byte identical to the repository fixture
before and after the guest run.

The generated guest runner used these two paths from the same current
directory:

```text
CompatNative native-command.txt T:AmShellM16/native-script.out
AmShell basic.script >T:AmShellM16/amshell-script.out
```

`native-command.txt` contains only `Execute basic.script`. `CompatNative`
supplied that opaque command to the original user Shell and captured stdout
through a DOS output handle. The candidate invoked the same `basic.script`
through AmShell, which delegated it to native `EXECUTE`. Capture did not edit
or wrap the fixture.

Both raw outputs contain `AmShell-script-start` and `AmShell-script-end`, the
same Kickstart/Workbench version line, the same `Avail` table structure and
maximum values, and both RC files contain `0`.

The only normalized values were the explicitly documented volatile `Avail`
`Available`, `In-Use`, and `Largest` counters. Native and AmShell naturally
used different transient fast memory. No other output or RC difference was
normalized.

## Harness qualification finding

The first visible run stopped before either execution path because the
generated `MakeDir` line used numbered `2>NIL:` redirection, which the qualified
AmigaOS 2.04 Shell does not support. No native or AmShell result was produced.
The raw temporary command stream and emulator log are retained under
`evidence/m1.6/attempt-1/`.

The smallest root-cause fix removed only `2>NIL:` from that generated line and
added a host structural check rejecting its return. No AmShell source, command
quoting, `EXECUTE` invocation, RC propagation or output comparison behavior was
changed. The complete clean build and visible guest qualification were then
rerun to the PASS recorded above.

## Evidence

- [comparator verdict](evidence/m1.6/comparator.txt)
- [raw native and AmShell results](evidence/m1.6/results/)
- [tested fixture](evidence/m1.6/basic.script),
  [native command](evidence/m1.6/native-command.txt), and
  [generated guest runner](evidence/m1.6/run-qualification.script)
- [guest OS version](evidence/m1.6/environment.out) and
  [CPU report](evidence/m1.6/cpu.out)
- [guest completion marker](evidence/m1.6/status.txt) and
  [qualification RC](evidence/m1.6/qualification.rc)
- [FS-UAE profile](evidence/m1.6/qualification.fs-uae),
  [version](evidence/m1.6/fs-uae-version.txt), and
  [byte-exact compressed emulator log](evidence/m1.6/fs-uae.log.txt.gz)
- [guest startup tail](evidence/m1.6/guest-startup-tail.script)
- [binary hashes and architecture check](evidence/m1.6/binary-hashes.txt)
- [preserved first failed harness attempt](evidence/m1.6/attempt-1/)

## Known limitations

- `Avail`'s `Available`, `In-Use`, and `Largest` numeric fields are retained in
  raw evidence but excluded from equality. Memory row names, table structure,
  `Maximum` values, surrounding output and RC remain compared.
- M1.6 compares stdout and numeric RC for one basic command file. It does not
  yet qualify stderr, every filesystem effect or all AmigaDOS script features.
- Command-file arguments and `.KEY` substitution remain explicitly outside
  M1.6 and are not implemented or qualified here.
- This result covers one A500/68000 Kickstart and Workbench 2.04 profile; it
  does not claim every later classic AmigaOS configuration.
