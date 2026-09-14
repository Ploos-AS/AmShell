# M1.5 FS-UAE / AmigaOS Differential Qualification

## Verdict

**PASS — 2026-09-14.** The first real classic AmigaOS runtime differential
qualification completed in visible, windowed FS-UAE. The native reference and
AmShell candidate produced equivalent deterministic observations for all 10
cases.

Exact comparator verdict:

```text
RESULT: PASS (10/10 cases equivalent)
```

Totals: **10 PASS, 0 FAIL**. No testcase was excluded.

## Qualified environment

- Amiga profile: FS-UAE A500, PAL, 1024 KiB chip RAM, 4096 KiB fast RAM,
  no slow RAM and no floppy drive
- CPU: Motorola 68000, no FPU; guest `CPU` reported
  `System: 68000 (INST: NoCache)`
- Kickstart: AmigaOS 2.04, revision 37.175
- Workbench/AmigaOS: Workbench 2.04, revision 37.67
- FS-UAE: 3.2.35, normal visible window (`fullscreen = 0`), not headless
- Toolchain: Bebbo `m68k-amigaos-gcc (GCC) 6.5.0b 20260807212032`
- Build flags: `-Os -Wall -Wextra -Werror -m68000`
- Runtime-tested AmShell commit: `4051b1ca859aba62771502fd8fd2c6cab9a9d5d0`
- AmShell SHA-256:
  `1e13bf9dd37dc28523e376f31500b4cf82893639582ccce3e60c2fc07806ca13`
- Differential corpus: 10 cases from `tests/compat/cases.txt`

The runtime-tested commit is the AmShell source revision used for the binary.
The qualification commit adds only harness, tests, documentation and evidence;
it does not change AmShell execution or parsing semantics.

## Execution and evidence

`make clean`, `make check`, `make`, and `make compat-bundle` passed before the
recorded run. `file` identified both bundled programs as AmigaOS loadseg()-able,
and `m68k-amigaos-objdump -f` reported `m68k:68000` for each. The bundled
AmShell was byte-for-byte identical to `build/AmShell`.

The guest booted a disposable directory-backed extraction of the local licensed
Workbench 2.04 disk. `Qualification:` exposed the complete generated bundle and
`Results:` exposed a fresh host result directory. The guest assigned `T:` to
`Results:`, changed to `Qualification:`, and executed
`run-qualification.script`. Both runners therefore inherited the same current
directory (`Qualification:compat`), assigns and command path.

The native side used the bundled 68000 `CompatNative` capture shim. It reads
each exact one-line command file as opaque text and supplies it to the original
user Shell with `SystemTagList()` and an explicit output handle. It contains no
shell parser. The candidate side supplied the same manifest command through
AmShell `-c`, whose established implementation delegates it to AmigaDOS.

The guest wrote all 20 stdout and 20 RC files, the qualification script returned
0, and the guest wrote `QUALIFICATION_COMPLETE`. Evidence retained in this
repository:

- [comparator verdict](evidence/m1.5/comparator.txt)
- [raw native and AmShell results](evidence/m1.5/results/)
- [manifest](evidence/m1.5/manifest.txt)
- [guest OS version](evidence/m1.5/environment.out) and
  [CPU report](evidence/m1.5/cpu.out)
- [guest completion marker](evidence/m1.5/status.txt) and
  [qualification RC](evidence/m1.5/qualification.rc)
- [FS-UAE profile](evidence/m1.5/qualification.fs-uae) and
  [guest startup tail](evidence/m1.5/guest-startup-tail.script)
- [FS-UAE version](evidence/m1.5/fs-uae-version.txt) and
  [emulator excerpt](evidence/m1.5/emulator-excerpt.txt)
- [binary hashes and architecture check](evidence/m1.5/binary-hashes.txt)

## Qualification fixes and failure analysis

The first runtime attempts exposed qualification-harness defects, not AmShell
command semantics:

1. Generated scripts used the non-AmigaDOS `2>NIL:` numbered redirection and
   the bundled binary was not addressable after changing into `compat/`. The
   scripts now use only native AmigaDOS redirection and native parent syntax
   `/AmShell`.
2. On AmigaDOS V40 and earlier, redirecting the CLI `Execute` command does not
   redirect the commands subsequently read from its script. Native commands
   returned RC 0 but their capture files were empty. `CompatNative` now provides
   the output handle directly to the original Shell without modifying or
   parsing the testcase command.
3. `Avail` correctly reported different transient free/in-use/largest fast
   memory because AmShell remains resident while its child Shell runs. The
   comparator now retains the raw output but normalizes only those volatile
   counters. Memory row structure, types and `Maximum` values remain compared;
   tests prove a changed stable maximum still fails.

After these fixes, host checks, native builds and the complete visible FS-UAE
qualification were rerun from clean state.

## Known limitations

- `Avail`'s `Available`, `In-Use`, and `Largest` numeric fields are captured but
  excluded from equality; its stable structure, memory types, `Maximum` values,
  and RC are compared.
- M1.5 compares stdout and numeric RC. It does not yet qualify stderr, complete
  filesystem effects, environment/local variables, or every session-state
  behavior.
- This result covers one A500/68000 Kickstart and Workbench 2.04 profile. It
  does not claim every later classic AmigaOS configuration.
