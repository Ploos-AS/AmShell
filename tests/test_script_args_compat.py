#!/usr/bin/env python3
"""Host-side smoke tests for the M1.7 script-argument qualification harness."""

from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
COMPARE = ROOT / "tools" / "script_args_compat_compare.py"
CASES = ROOT / "tests" / "compat" / "script_args_cases.tsv"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def case_ids():
    ids = []
    for raw in CASES.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        ids.append(raw.split("\t", 1)[0])
    return ids


def main() -> int:
    ids = case_ids()
    if len(ids) < 6:
        print("FAIL: M1.7 argument corpus is too small")
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        results = Path(tmp)
        for case_id in ids:
            for mode in ("native", "amshell"):
                (results / f"{mode}-{case_id}.out").write_text(
                    f"same-{case_id}\n", encoding="latin-1"
                )
                (results / f"{mode}-{case_id}.rc").write_text("0\n", encoding="latin-1")

        equal = run(str(COMPARE), str(results))
        if equal.returncode != 0 or "RESULT: PASS" not in equal.stdout:
            print(equal.stdout)
            return 1

        first = ids[0]
        (results / f"amshell-{first}.rc").write_text("5\n", encoding="latin-1")
        different = run(str(COMPARE), str(results))
        if different.returncode == 0 or "RESULT: FAIL" not in different.stdout:
            print(different.stdout)
            return 1

    print("PASS: AmShell M1.7 script-argument harness smoke tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
