# AmShell

**AmShell** is a modern interactive shell for classic AmigaOS, designed to add contemporary interactive features while preserving compatibility with the original Amiga Shell and AmigaDOS command environment.

## Project goals

AmShell aims to provide:

- original Amiga Shell / AmigaDOS compatibility as a primary design constraint
- interactive command-line editing
- command history, including persistent history
- smart tab completion for commands, files, directories, devices and assigns
- aliases and configurable prompts
- scripting and non-interactive execution
- first-class ARexx integration
- a lightweight implementation suitable for classic 68k Amigas

## Compatibility first

Compatibility is not an optional feature. Existing AmigaDOS commands, scripts, startup files, quoting rules, redirection, pipes and return-code behaviour must continue to work as expected wherever AmShell claims compatibility.

New interactive features must not silently redefine established Amiga Shell syntax.

See [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md) for the compatibility contract.

## Initial target

- AmigaOS 2.04+
- Motorola 68000+
- no FPU required
- classic AmigaDOS environment
- Bebbo `m68k-amigaos-gcc` toolchain

## Status

M0 — repository foundation and architecture definition.

## License

MIT. See [`LICENSE`](LICENSE).
