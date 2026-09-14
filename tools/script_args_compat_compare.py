#!/usr/bin/env python3
"""Compare native EXECUTE and AmShell script-argument results."""

from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
CASES = ROOT / "tests" / "compat" / "script_args_cases.tsv"


def read_text(path: Path) -> str:
    return path.read_text(encoding="latin-1").replace("\r\n", "\n").replace("\r", "\n")


def load_cases():
    cases = []
    for raw in CASES.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        case_id, script, arguments = raw.split("\t", 2)
        cases.append((case_id, script, arguments))
    return cases


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path)
    args = parser.parse_args()

    failures = 0
    cases = load_cases()

    for case_id, script, arguments in cases:
        paths = {
            "native_out": args.results / f"native-{case_id}.out",
            "native_rc": args.results / f"native-{case_id}.rc",
            "amshell_out": args.results / f"amshell-{case_id}.out",
            "amshell_rc": args.results / f"amshell-{case_id}.rc",
        }
        missing = [name for name, path in paths.items() if not path.is_file()]
        if missing:
            print(f"FAIL {case_id}: missing {', '.join(missing)}")
            failures += 1
            continue

        native_out = read_text(paths["native_out"])
        native_rc = read_text(paths["native_rc"]).strip()
        amshell_out = read_text(paths["amshell_out"])
        amshell_rc = read_text(paths["amshell_rc"]).strip()

        mismatch = []
        if native_rc != amshell_rc:
            mismatch.append(f"RC native={native_rc!r} amshell={amshell_rc!r}")
        if native_out != amshell_out:
            mismatch.append("output differs")

        invocation = f"{script} {arguments}".rstrip()
        if mismatch:
            print(f"FAIL {case_id}: {'; '.join(mismatch)} :: {invocation}")
            failures += 1
        else:
            print(f"PASS {case_id}: {invocation} :: RC {native_rc}")

    if failures:
        print(f"RESULT: FAIL ({failures}/{len(cases)} cases differ)")
        return 1

    print(f"RESULT: PASS ({len(cases)}/{len(cases)} cases equivalent)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
