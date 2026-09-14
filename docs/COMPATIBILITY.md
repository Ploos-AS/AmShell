# AmShell Compatibility Contract

Compatibility with the original Amiga Shell and AmigaDOS is a first-class requirement of AmShell.

## Principle

A user should be able to replace an original interactive Shell session with AmShell without unexpectedly changing the meaning of existing AmigaDOS commands or scripts.

Modern features are additive. They must not silently repurpose established syntax.

## M0 compatibility rules

AmShell development must preserve or explicitly test:

1. AmigaDOS command invocation and argument passing.
2. Amiga path syntax, including volumes, devices and assigns.
3. Existing quoting and escaping semantics.
4. Redirection and pipe syntax supported by the target AmigaOS Shell.
5. Return-code behaviour (`RC`) and command failure propagation.
6. Environment/local variables and process context where applicable.
7. Script execution semantics and compatibility with existing command files.
8. `C:`/command-path lookup expectations.
9. Current-directory behaviour.
10. Startup/configuration interoperability where practical.

## Extension rule

History, completion, aliases, enhanced prompts, line editing and ARexx integration are interactive extensions. Unless explicitly enabled, an extension must not alter the interpretation of an otherwise valid original-shell command line.

## Compatibility modes

The architecture should permit a strict compatibility mode. Features whose syntax could conflict with original Shell behaviour must either:

- use syntax that cannot conflict,
- be limited to interactive editing before command submission, or
- require explicit opt-in.

## Regression strategy

Before v0.1.0, AmShell will maintain a compatibility corpus containing representative original Amiga Shell commands and scripts. Where feasible, the same corpus should be executed under the original Shell and AmShell and observable results compared.

Target environments begin with AmigaOS 2.04+ and expand across later classic AmigaOS releases.

## Non-goal

AmShell is not intended to become a Bash/POSIX compatibility layer at the expense of Amiga Shell compatibility.
