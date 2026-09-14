# M1.6 Command-File Runtime Qualification

M1.6 runtime qualification compares native AmigaDOS `EXECUTE` with the AmShell command-file interface using the same script fixture.

## Prepare

On the host:

```sh
make clean
make check
make script-compat-bundle
```

The qualification directory is:

```text
build/m1.6-qualification/
```

It contains:

- `AmShell`
- `CompatNative`
- `basic.script`
- `native-command.txt`
- `run-qualification.script`
- `README.txt`

## Guest run

Use a visible FS-UAE session and the same AmigaOS environment used for the M1.5 qualification where practical.

Make `build/m1.6-qualification/` available to the guest, make it the current directory and run:

```text
Execute run-qualification.script
```

The guest writes:

```text
T:AmShellM16/native-script.out
T:AmShellM16/native-script.rc
T:AmShellM16/amshell-script.out
T:AmShellM16/amshell-script.rc
```

The native path executes `Execute basic.script` through `CompatNative`, which delegates the exact command to the original Shell while capturing output using DOS handles rather than modifying the script under test.

The candidate path runs:

```text
AmShell basic.script
```

AmShell must delegate the command file to native AmigaDOS `EXECUTE`; it must not parse script lines itself.

## Compare

Copy the four result files to a host directory and run:

```sh
python3 tools/script_compat_compare.py RESULTS_DIR
```

PASS requires equivalent RC and output. The only normalization currently permitted is the same volatile `Avail` counter normalization documented for M1.5; stable table structure and maximum values remain compared.

## Status

The M1.6 runtime qualification harness is implemented and host-smoke-tested. This document does not claim an FS-UAE/AmigaOS runtime PASS until actual guest evidence has been collected and the comparator has emitted `RESULT: PASS`.
