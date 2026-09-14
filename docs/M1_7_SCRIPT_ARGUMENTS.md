# M1.7 Script Arguments and `.KEY`

M1.7 extends command-file execution so AmShell can invoke:

```text
AmShell scriptfile arg1 arg2 ...
```

The compatibility rule remains unchanged: AmShell does not parse `.KEY`, perform substitution, or implement an independent command-file argument language.

AmShell reconstructs only the outer native `EXECUTE` invocation and delegates the complete command to the AmigaDOS system Shell. Each argument received by AmShell is emitted as an AmigaDOS quoted argument with `*`/quote escaping so the value delivered by the caller remains a single `EXECUTE` argument.

`.KEY`, `.BRA`, `.KET`, defaults, required parameters, keyword parameters, switches, numeric conversion and substitution therefore remain native AmigaDOS behavior and must be qualified differentially against direct `EXECUTE`.

## Initial fixture

`tests/compat/scripts/args.script` provides the first M1.7 differential fixture:

```text
.KEY FIRST/A,SECOND,MODE/K
Echo AmShell-args-start
Echo first=<FIRST>
Echo second=<SECOND>
Echo mode=<MODE>
Echo AmShell-args-end
```

The first runtime corpus should cover at least:

- required positional argument;
- optional positional argument;
- keyword argument;
- omitted optional values;
- arguments containing spaces;
- quote/escape preservation;
- native failure behavior when `/A` is omitted.

Further fixtures should then cover `/N`, `/S`, defaults and custom `.BRA`/`.KET` before M1.7 runtime qualification is marked complete.

## Qualification status

Implementation and host structural checks may pass independently of guest qualification. M1.7 remains runtime-pending until direct native `EXECUTE` and AmShell produce equivalent output and RC on the supported AmigaOS 2.04 / 68000 baseline.
