# M1.7 Runtime Qualification

M1.7 qualifies command-file argument forwarding against direct native AmigaDOS `EXECUTE`.

## Scope

The first runtime matrix uses `tests/compat/scripts/args.script`:

```text
.KEY FIRST/A,SECOND,MODE/K
Echo AmShell-args-start
Echo first=<FIRST>
Echo second=<SECOND>
Echo mode=<MODE>
Echo AmShell-args-end
```

The corpus in `tests/compat/script_args_cases.tsv` covers:

- required positional argument;
- two positional arguments;
- keyword argument;
- omitted optional positional value;
- a quoted argument containing spaces;
- native failure behavior when the required `/A` argument is missing.

This milestone does not yet claim `/N`, `/S`, defaults or custom `.BRA`/`.KET` qualification. Those require dedicated fixtures after this baseline passes.

## Host preparation

Run:

```text
make clean
make check
make
make script-args-compat-bundle
```

The bundle is created under:

```text
build/m1.7-qualification/
```

## Guest qualification

Use visible FS-UAE and the same AmigaOS 2.04 / A500 / 68000 baseline used by M1.5 and M1.6.

Run the bundle directory as the current directory and execute:

```text
Execute run-qualification.script
```

For every corpus case, the harness executes the same outer argument text through:

```text
Execute args.script ...
```

and:

```text
AmShell args.script ...
```

The native path is captured through `CompatNative` so output capture does not alter the tested native command text.

Copy all files from `T:AmShellM17/` back to a host results directory and run:

```text
python3 tools/script_args_compat_compare.py RESULTS_DIR
```

## PASS criteria

M1.7 baseline runtime qualification passes only when every case has:

- native result files present;
- AmShell result files present;
- identical return code;
- identical captured output.

No output normalization is expected for `args.script`.

A failure case such as omitted `/A` does not need RC 0; it must match the native `EXECUTE` result exactly.

Do not mark M1.7 runtime PASS until visible AmigaOS guest evidence has been collected and the comparator emits explicit `RESULT: PASS`.
