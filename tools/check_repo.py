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
    "docs/ARCHITECTURE.md",
    "docs/COMPATIBILITY.md",
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
    if "src/exec.c" not in makefile:
        fail("Makefile does not build the execution backend")

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

    backend = (ROOT / "src/exec.c").read_text(encoding="utf-8")
    if "SystemTagList" not in backend:
        fail("execution backend does not delegate to AmigaDOS SystemTagList")
    if "SYS_UserShell" not in backend:
        fail("execution backend does not explicitly select Shell compatibility")

    print("PASS: AmShell M1.1 repository checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
