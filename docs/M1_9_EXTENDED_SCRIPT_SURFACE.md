# M1.9 Extended Native Script Surface

M1.9 broadens the deferred M1 final qualification corpus without changing AmShell command-file semantics.

AmShell still reconstructs only the outer native `EXECUTE` invocation. All `.KEY` processing, numeric validation, switch handling, defaults and bracket substitution remain owned by AmigaDOS.

## Added fixtures

- `tests/compat/scripts/args_types.script`
  - `/N` numeric argument
  - `/S` switch argument
  - valid and invalid numeric cases
- `tests/compat/scripts/args_defaults.script`
  - `.DEF` defaults
  - inline `$` defaults
  - explicit override
- `tests/compat/scripts/args_brackets.script`
  - `.BRA` / `.KET` redefinition
  - literal angle brackets after redefinition

`tests/compat/script_args_cases.tsv` now selects the fixture per case. The qualification bundle copies every referenced script and runs the same script plus outer argument text through both direct native `EXECUTE` and `AmShell`.

No output normalization is used for these cases. Both stdout and RC must match.

## Runtime policy

Runtime execution remains deliberately deferred to the combined M1 final qualification on visible FS-UAE / AmigaOS 2.04 / 68000. Host checks and harness construction may pass before that run, but deferred cases must not be described as runtime PASS.

## CD compatibility boundary

M1.8 deliberately handles exact paths in-process so persistent current-directory state is preserved. Pattern or compound `CD` syntax is delegated unchanged to the native Shell rather than duplicated in AmShell.

This preserves syntax and diagnostics, but state transfer after a pattern-resolved child-Shell `CD` remains an explicit qualification/design boundary. It must not be silently claimed equivalent until the combined M1 qualification demonstrates an acceptable solution or records the limitation.
