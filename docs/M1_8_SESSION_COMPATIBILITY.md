# M1.8 Session Compatibility: `CD`, `ENDCLI`, and `ENDSHELL`

M1.8 tightens AmShell's interactive-session compatibility with the original Amiga Shell while preserving the rule that ordinary command semantics remain owned by AmigaDOS.

## Native shell termination

The original Shell is terminated with the internal `ENDCLI` or `ENDSHELL` commands. `EXIT` is not treated as an Amiga Shell termination command by AmShell.

AmShell therefore intercepts only standalone, case-insensitive `ENDCLI` and `ENDSHELL` lines (allowing surrounding spaces/tabs) so that they terminate the AmShell interactive loop itself rather than only a child Shell started by `SystemTagList()`.

All other lines, including `EXIT`, continue through the normal native execution path.

## Persistent `CD`

A child Shell cannot change AmShell's process current directory, so AmShell must retain a narrow stateful `CD` path.

M1.8 broadens this conservative path to support exact directory arguments with:

- surrounding whitespace;
- exact unquoted Amiga paths;
- exact quoted paths containing spaces;
- AmigaDOS `*"` and `**` escapes inside a quoted exact path;
- native path forms such as `/`, `//`, `:` and device/assign paths when `Lock()` resolves them.

AmShell does not implement AmigaDOS pattern matching. Lines containing pattern/shell syntax are delegated unchanged to the native Shell. This preserves native diagnostics and avoids inventing a competing parser, but such delegated `CD` commands cannot yet persist a child-only directory change into AmShell's own process.

That remaining gap is intentionally deferred to the final M1 compatibility qualification/work before M1 is declared complete.

## Qualification policy

Host structural/CI checks can pass now. Runtime verification for M1.7 and M1.8 is deliberately deferred and will be included in the combined M1 final visible-FS-UAE qualification on the AmigaOS 2.04 / 68000 baseline.

No runtime PASS is claimed by this document.
