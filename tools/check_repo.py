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
    "tests/test_compat_tools.py",
    "tools/compat_prepare.py",
    "tools/compat_compare.py",
    "docs/ARCHITECTURE.md",
    "docs/COMPATIBILITY.md",
    "docs/M1_4_DIFFERENTIAL_QUALIFICATION.md",
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
    if "check:" not in makefile:
        fail("Makefile has no check target")
    if "compat-prepare:" not in makefile:
        fail("Makefile has no differential compatibility preparation target")
    if "tests/test_compat_tools.py" not in makefile:
        fail("make check does not execute compatibility harness smoke tests")
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

    backend = (ROOT / "src/exec.c").read_text(encoding="utf-8")
    if "SystemTagList" not in backend:
        fail("execution backend does not delegate to AmigaDOS SystemTagList")
    if "SYS_UserShell" not in backend:
        fail("execution backend does not explicitly select Shell compatibility")

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

    prepare = (ROOT / "tools/compat_prepare.py").read_text(encoding="utf-8")
    compare = (ROOT / "tools/compat_compare.py").read_text(encoding="utf-8")
    if "run-native.script" not in prepare or "run-amshell.script" not in prepare:
        fail("differential harness does not prepare both execution paths")
    if "native-{case_id}.script" not in prepare:
        fail("native harness does not preserve testcase text in command files")
    if "RESULT: FAIL" not in compare or "RESULT: PASS" not in compare:
        fail("differential comparator has no explicit verdict")

    print("PASS: AmShell M1.4 repository checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
