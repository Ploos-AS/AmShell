#!/usr/bin/env python3
"""Host-side structural checks for the AmShell repository."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "README.md",
    "ROADMAP.md",
    "LICENSE",
    "Makefile",
    "src/main.c",
    "src/exec.c",
    "src/exec.h",
    "src/session.c",
    "src/session.h",
    "tests/compat/cases.txt",
    "tests/compat/scripts/basic.script",
    "tests/compat/scripts/args.script",
    "tests/compat/script_args_cases.tsv",
    "tests/test_compat_tools.py",
    "tests/test_script_compat.py",
    "tests/test_script_args_compat.py",
    "tools/compat_prepare.py",
    "tools/compat_compare.py",
    "tools/compat_bundle.py",
    "tools/compat_native.c",
    "tools/script_compat_compare.py",
    "tools/script_compat_bundle.py",
    "tools/script_args_compat_compare.py",
    "tools/script_args_compat_bundle.py",
    "docs/ARCHITECTURE.md",
    "docs/COMPATIBILITY.md",
    "docs/M1_4_DIFFERENTIAL_QUALIFICATION.md",
    "docs/M1_5_RUNTIME_QUALIFICATION.md",
    "docs/M1_5_QUALIFICATION.md",
    "docs/M1_6_COMMAND_FILE_EXECUTION.md",
    "docs/M1_6_RUNTIME_QUALIFICATION.md",
    "docs/M1_6_QUALIFICATION.md",
    "docs/M1_7_SCRIPT_ARGUMENTS.md",
    "docs/M1_7_RUNTIME_QUALIFICATION.md",
)

REQUIRED_COMPATIBILITY_TERMS = (
    "compatibility",
    "AmigaDOS",
    "return",
)


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).is_file():
            fail(f"missing required file: {rel}")

    makefile = (ROOT / "Makefile").read_text(encoding="utf-8")
    if "-m68000" not in makefile:
        fail("Makefile does not declare the 68000 baseline")
    for target in (
        "check:",
        "compat-prepare:",
        "compat-bundle:",
        "script-compat-bundle:",
        "script-args-compat-bundle:",
    ):
        if target not in makefile:
            fail(f"Makefile missing target: {target}")
    if "tools/compat_native.c" not in makefile:
        fail("qualification build does not include native Shell capture launcher")
    for test in (
        "tests/test_compat_tools.py",
        "tests/test_script_compat.py",
        "tests/test_script_args_compat.py",
    ):
        if test not in makefile:
            fail(f"make check does not execute {test}")
    for source in ("src/exec.c", "src/session.c"):
        if source not in makefile:
            fail(f"Makefile does not build {source}")

    compat = (ROOT / "docs/COMPATIBILITY.md").read_text(encoding="utf-8")
    folded = compat.casefold()
    for term in REQUIRED_COMPATIBILITY_TERMS:
        if term.casefold() not in folded:
            fail(f"compatibility contract is missing required term: {term}")

    source = (ROOT / "src/main.c").read_text(encoding="utf-8")
    if "AMSHELL_VERSION" not in source:
        fail("entrypoint has no version identifier")
    if 'strcmp(argv[1], "-c")' not in source:
        fail("entrypoint has no -c execution path")
    if "interactive_loop" not in source:
        fail("entrypoint has no interactive command loop")
    if "last_rc" not in source:
        fail("interactive session does not retain the last return code")
    if "amshell_session_execute" not in source:
        fail("interactive loop bypasses session-state execution")
    if "amshell_execute_file_args" not in source:
        fail("entrypoint has no M1.7 command-file argument path")

    backend = (ROOT / "src/exec.c").read_text(encoding="utf-8")
    if "SystemTagList" not in backend:
        fail("execution backend does not delegate to AmigaDOS SystemTagList")
    if "SYS_UserShell" not in backend:
        fail("execution backend does not explicitly select Shell compatibility")
    if 'strcpy(command, "Execute ")' not in backend:
        fail("command-file backend does not delegate scripts to native EXECUTE")
    if "amshell_execute_file_args" not in backend:
        fail("execution backend has no command-file argument entrypoint")
    if "append_quoted_arg" not in backend:
        fail("M1.7 argument forwarding lacks AmigaDOS-safe quoting")

    session = (ROOT / "src/session.c").read_text(encoding="utf-8")
    if "CurrentDir" not in session or "Lock(" not in session:
        fail("session module has no persistent current-directory path")
    if "contains_shell_syntax" not in session:
        fail("session CD handling lacks conservative syntax guard")

    cases = [
        line.strip()
        for line in (ROOT / "tests/compat/cases.txt").read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if len(cases) < 8:
        fail("compatibility corpus is too small for M1 baseline")

    script_fixture = (ROOT / "tests/compat/scripts/basic.script").read_text(encoding="utf-8")
    if "Echo AmShell-script-start" not in script_fixture or "Echo AmShell-script-end" not in script_fixture:
        fail("M1.6 command-file fixture is incomplete")

    args_fixture = (ROOT / "tests/compat/scripts/args.script").read_text(encoding="utf-8")
    for marker in (".KEY FIRST/A,SECOND,MODE/K", "<FIRST>", "<SECOND>", "<MODE>"):
        if marker not in args_fixture:
            fail(f"M1.7 script-argument fixture missing marker: {marker}")

    arg_cases = [
        line for line in (ROOT / "tests/compat/script_args_cases.tsv").read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if len(arg_cases) < 6:
        fail("M1.7 script-argument corpus is too small")

    prepare = (ROOT / "tools/compat_prepare.py").read_text(encoding="utf-8")
    compare = (ROOT / "tools/compat_compare.py").read_text(encoding="utf-8")
    bundle = (ROOT / "tools/compat_bundle.py").read_text(encoding="utf-8")
    script_compare = (ROOT / "tools/script_compat_compare.py").read_text(encoding="utf-8")
    script_bundle = (ROOT / "tools/script_compat_bundle.py").read_text(encoding="utf-8")
    args_compare = (ROOT / "tools/script_args_compat_compare.py").read_text(encoding="utf-8")
    args_bundle = (ROOT / "tools/script_args_compat_bundle.py").read_text(encoding="utf-8")

    if "run-native.script" not in prepare or "run-amshell.script" not in prepare:
        fail("differential harness does not prepare both execution paths")
    if "native-{case_id}.script" not in prepare:
        fail("native harness does not preserve testcase text in command files")
    if "RESULT: FAIL" not in compare or "RESULT: PASS" not in compare:
        fail("differential comparator has no explicit verdict")
    if "run-qualification.script" not in bundle or "m1.5-qualification" not in bundle:
        fail("M1.5 bundle tool does not create the guest qualification package")
    if "RESULT: FAIL" not in script_compare or "RESULT: PASS" not in script_compare:
        fail("M1.6 script comparator has no explicit verdict")
    for marker in ("m1.6-qualification", "native-command.txt", "run-qualification.script"):
        if marker not in script_bundle:
            fail(f"M1.6 script bundle missing marker: {marker}")
    if "2>NIL:" in script_bundle:
        fail("M1.6 script bundle uses unsupported numbered AmigaDOS redirection")

    if "RESULT: FAIL" not in args_compare or "RESULT: PASS" not in args_compare:
        fail("M1.7 argument comparator has no explicit verdict")
    for marker in ("m1.7-qualification", "script_args_cases.tsv", "run-qualification.script"):
        if marker not in args_bundle:
            fail(f"M1.7 argument bundle missing marker: {marker}")
    if "2>NIL:" in args_bundle:
        fail("M1.7 argument bundle uses unsupported numbered AmigaDOS redirection")

    print("PASS: AmShell M1.7 repository and runtime-harness checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
