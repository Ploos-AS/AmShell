#!/usr/bin/env python3
"""Compare native EXECUTE and AmShell command-file observations."""

from pathlib import Path
import argparse
import re


def normalize_newlines(data: str) -> str:
    return data.replace("\r\n", "\n").replace("\r", "\n")


def normalize_avail_lines(data: str) -> str:
    """Normalize volatile AVAIL counters while retaining stable structure."""
    out = []
    avail_re = re.compile(r"^(chip|fast|total)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$", re.I)
    for line in normalize_newlines(data).splitlines():
        m = avail_re.match(line)
        if m:
            out.append(f"{m.group(1).casefold()} maximum={m.group(4)}")
        else:
            out.append(line)
    return "\n".join(out) + ("\n" if data.endswith(("\n", "\r")) else "")


def read(path: Path) -> str:
    return path.read_text(encoding="latin-1")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path)
    args = parser.parse_args()

    required = {
        "native_out": args.results / "native-script.out",
        "native_rc": args.results / "native-script.rc",
        "amshell_out": args.results / "amshell-script.out",
        "amshell_rc": args.results / "amshell-script.rc",
    }
    missing = [name for name, path in required.items() if not path.is_file()]
    if missing:
        print("RESULT: FAIL (missing: " + ", ".join(missing) + ")")
        return 1

    native_rc = normalize_newlines(read(required["native_rc"])).strip()
    amshell_rc = normalize_newlines(read(required["amshell_rc"])).strip()
    native_out = normalize_avail_lines(read(required["native_out"]))
    amshell_out = normalize_avail_lines(read(required["amshell_out"]))

    failures = []
    if native_rc != amshell_rc:
        failures.append(f"RC native={native_rc!r} amshell={amshell_rc!r}")
    if native_out != amshell_out:
        failures.append("output differs")

    if failures:
        print("RESULT: FAIL (" + "; ".join(failures) + ")")
        return 1

    print("RESULT: PASS (native EXECUTE and AmShell command-file behavior equivalent)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
