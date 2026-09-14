#!/usr/bin/env python3
"""Host-side smoke tests for the M1.4 differential harness."""

from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PREPARE = ROOT / "tools" / "compat_prepare.py"
COMPARE = ROOT / "tools" / "compat_compare.py"
CASES = ROOT / "tests" / "compat" / "cases.txt"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "prepared"
        result = run(str(PREPARE), "--cases", str(CASES), "--out", str(out))
        if result.returncode != 0:
            print(result.stdout)
            return 1

        required = (
            out / "manifest.txt",
            out / "run-native.script",
            out / "run-amshell.script",
            out / "cases" / "native-001.script",
        )
        for path in required:
            if not path.is_file():
                print(f"FAIL: compat_prepare missing {path.name}")
                return 1

        corpus = [
            line.strip()
            for line in CASES.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        first = (out / "cases" / "native-001.script").read_text(encoding="utf-8").strip()
        if first != corpus[0]:
            print("FAIL: native command file did not preserve exact command text")
            return 1

        results = Path(tmp) / "results"
        results.mkdir()
        manifest = Path(tmp) / "manifest.txt"
        manifest.write_text("001\tEcho test\n", encoding="utf-8")
        for mode in ("native", "amshell"):
            (results / f"{mode}-001.out").write_text("same\n", encoding="latin-1")
            (results / f"{mode}-001.rc").write_text("0\n", encoding="latin-1")

        equal = run(str(COMPARE), str(results), "--manifest", str(manifest))
        if equal.returncode != 0 or "RESULT: PASS" not in equal.stdout:
            print(equal.stdout)
            return 1

        (results / "amshell-001.rc").write_text("5\n", encoding="latin-1")
        different = run(str(COMPARE), str(results), "--manifest", str(manifest))
        if different.returncode == 0 or "RESULT: FAIL" not in different.stdout:
            print(different.stdout)
            return 1

    print("PASS: AmShell M1.4 compatibility harness smoke tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
