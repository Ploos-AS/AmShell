# M1.11 — bare-name implied-CD precedence

## Purpose

Amiga Shell can treat a directory-like token as an implied `CD`. For path-like tokens such as `SYS:Tools`, M1.10 can safely transfer current-directory state directly. A bare token such as `Tools` is more ambiguous because the same name may also resolve as a command.

AmShell must not invent its own precedence rule. Original Shell compatibility remains authoritative.

## Native precedence probe

`tests/compat/implied_cd_cases.tsv` defines the deferred probe surface and `tools/implied_cd_probe_bundle.py` packages the visible-AmigaOS test.

Build with:

```text
make clean
make check
make
make implied-cd-probe-bundle
```

Run `build/m1.11-qualification/run-native-probe.script` on the visible A500/68000 + AmigaOS 2.04 qualification profile.

The probe records three observations for each native case:

- command output
- command return code
- resulting current directory

The collision case intentionally provides both a directory and an executable command with the same bare name. Its native result determines the command-vs-directory precedence that AmShell must reproduce.

## Compatibility rule

Until the native probe has been executed and recorded, bare-name implied-CD tokens remain delegated unchanged to the system Shell. This preserves command execution semantics but means a child Shell's implied directory change cannot yet persist in the parent AmShell session.

Do not implement a guessed precedence rule and do not mark M1.11 PASS from host checks alone.

Runtime execution is deferred to the combined M1 final qualification, together with the remaining M1.7–M1.10 deferred cases.
