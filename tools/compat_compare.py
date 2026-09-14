#!/usr/bin/env python3
"""Compare collected native-Shell and AmShell differential results."""

from pathlib import Path
import argparse
import sys


def normalize_output(data: str) -> str:
    return data.replace("\r\n", "\n").replace("\r", "\n")


def read_text(path: Path) -> str:
    return normalize_output(path.read_text(encoding="latin-1"))


def comparable_output(command: str, data: str) -> str:
    """Remove only testcase fields that are inherently observation-volatile."""
    if command.casefold() != "avail":
        return data

    lines = data.splitlines()
    normalized = []
    for line in lines:
        fields = line.split()
        if (
            len(fields) == 5
            and fields[0].casefold() in ("chip", "fast", "total")
            and all(field.isdigit() for field in fields[1:])
        ):
            # Available, In-Use and Largest necessarily include the memory
            # occupied by the command's launcher. Maximum is stable and is
            # retained along with the memory type and table structure.
            normalized.append(f"{fields[0].casefold()} maximum={fields[3]}")
        else:
            normalized.append(line)
    return "\n".join(normalized) + ("\n" if data.endswith("\n") else "")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()

    failures = 0
    total = 0

    for raw in args.manifest.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        case_id, command = raw.split("\t", 1)
        total += 1

        paths = {
            "native_out": args.results / f"native-{case_id}.out",
            "native_rc": args.results / f"native-{case_id}.rc",
            "amshell_out": args.results / f"amshell-{case_id}.out",
            "amshell_rc": args.results / f"amshell-{case_id}.rc",
        }
        missing = [name for name, path in paths.items() if not path.is_file()]
        if missing:
            print(f"FAIL {case_id}: missing {', '.join(missing)} :: {command}")
            failures += 1
            continue

        native_out = read_text(paths["native_out"])
        amshell_out = read_text(paths["amshell_out"])
        native_rc = read_text(paths["native_rc"]).strip()
        amshell_rc = read_text(paths["amshell_rc"]).strip()

        mismatch = []
        if native_rc != amshell_rc:
            mismatch.append(f"RC native={native_rc!r} amshell={amshell_rc!r}")
        if comparable_output(command, native_out) != comparable_output(
            command, amshell_out
        ):
            mismatch.append("output differs")

        if mismatch:
            print(f"FAIL {case_id}: {'; '.join(mismatch)} :: {command}")
            failures += 1
        else:
            note = (
                " (volatile Avail counters normalized)"
                if command.casefold() == "avail"
                else ""
            )
            print(f"PASS {case_id}: {command}{note}")

    if failures:
        print(f"RESULT: FAIL ({failures}/{total} cases differ)")
        return 1

    print(f"RESULT: PASS ({total}/{total} cases equivalent)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
