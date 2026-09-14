#!/usr/bin/env python3
"""Host-side structural test for the combined M1 qualification bundle."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "m1_final_bundle.py"


def main() -> int:
    text = TOOL.read_text(encoding="utf-8")

    required = (
        '"compat_bundle.py"',
        '"script_compat_bundle.py"',
        '"script_args_compat_bundle.py"',
        '"implied_cd_probe_bundle.py"',
        '"m1.5"',
        '"m1.6"',
        '"m1.7-m1.9"',
        '"m1.11"',
        "run-m1-final.script",
        "T:AmShellCompat",
        "T:AmShellM16",
        "T:AmShellM17",
        "Runtime verdict: PENDING",
    )
    for marker in required:
        if marker not in text:
            print(f"FAIL: combined M1 bundle missing marker: {marker}")
            return 1

    forbidden = (
        "Runtime verdict: PASS",
        "RESULT: PASS",
    )
    for marker in forbidden:
        if marker in text:
            print(f"FAIL: combined M1 bundle makes premature runtime claim: {marker}")
            return 1

    print("PASS: combined M1 qualification bundle structure")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
