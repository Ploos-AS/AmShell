#!/usr/bin/env python3
"""Host smoke tests for the M1.6 command-file differential comparator."""

from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
COMPARE = ROOT / "tools" / "script_compat_compare.py"


def run(results: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(COMPARE), str(results)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def write_pair(results: Path, native_out: str, amshell_out: str, native_rc: str = "0\n", amshell_rc: str = "0\n") -> None:
    (results / "native-script.out").write_text(native_out, encoding="latin-1")
    (results / "amshell-script.out").write_text(amshell_out, encoding="latin-1")
    (results / "native-script.rc").write_text(native_rc, encoding="latin-1")
    (results / "amshell-script.rc").write_text(amshell_rc, encoding="latin-1")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        results = Path(tmp)
        write_pair(results, "same\n", "same\n")
        equal = run(results)
        if equal.returncode != 0 or "RESULT: PASS" not in equal.stdout:
            print(equal.stdout)
            return 1

        write_pair(results, "same\n", "different\n")
        different = run(results)
        if different.returncode == 0 or "RESULT: FAIL" not in different.stdout:
            print(different.stdout)
            return 1

        native = (
            "Type Available In-Use Maximum Largest\n"
            "chip 900 100 1000 800\n"
            "fast 1800 200 2000 1700\n"
            "total 2700 300 3000 1700\n"
        )
        candidate = (
            "Type Available In-Use Maximum Largest\n"
            "chip 850 150 1000 750\n"
            "fast 1750 250 2000 1650\n"
            "total 2600 400 3000 1650\n"
        )
        write_pair(results, native, candidate)
        volatile = run(results)
        if volatile.returncode != 0 or "RESULT: PASS" not in volatile.stdout:
            print(volatile.stdout)
            return 1

    print("PASS: AmShell M1.6 command-file harness smoke tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
