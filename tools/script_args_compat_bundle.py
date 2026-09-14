#!/usr/bin/env python3
"""Build the M1.7/M1.9 script-argument runtime qualification package."""

from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "m1.7-qualification"
CASES = ROOT / "tests" / "compat" / "script_args_cases.tsv"
SCRIPTS = ROOT / "tests" / "compat" / "scripts"


def load_cases():
    cases = []
    for raw in CASES.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        case_id, script, arguments = raw.split("\t", 2)
        cases.append((case_id, script, arguments))
    return cases


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    commands = OUT / "commands"
    commands.mkdir(exist_ok=True)

    for name in ("AmShell", "CompatNative"):
        src = ROOT / "build" / name
        if not src.is_file():
            raise SystemExit(f"missing {src}; build first")
        shutil.copy2(src, OUT / name)

    cases = load_cases()
    for script in sorted({script for _, script, _ in cases}):
        shutil.copy2(SCRIPTS / script, OUT / script)
    shutil.copy2(CASES, OUT / "script_args_cases.tsv")

    guest = [
        "; AmShell M1.7/M1.9 script-argument differential qualification",
        "FailAt 20",
        "MakeDir T:AmShellM17 >NIL:",
    ]

    for case_id, script, arguments in cases:
        suffix = f" {arguments}" if arguments else ""
        native_command = f"Execute {script}{suffix}"
        command_file = commands / f"native-{case_id}.txt"
        command_file.write_text(native_command + "\n", encoding="ascii", newline="\n")
        guest.extend(
            [
                f"CompatNative commands/native-{case_id}.txt T:AmShellM17/native-{case_id}.out",
                f"Echo $RC >T:AmShellM17/native-{case_id}.rc",
                f"AmShell {script}{suffix} >T:AmShellM17/amshell-{case_id}.out",
                f"Echo $RC >T:AmShellM17/amshell-{case_id}.rc",
            ]
        )

    guest.append("Echo M1.7/M1.9 guest run complete")
    (OUT / "run-qualification.script").write_text(
        "\n".join(guest) + "\n", encoding="ascii", newline="\n"
    )

    (OUT / "README.txt").write_text(
        "AmShell M1 script-argument runtime qualification\n\n"
        "Run this directory as the current directory on visible FS-UAE/AmigaOS 2.04.\n"
        "Execute run-qualification.script\n\n"
        "Copy all files from T:AmShellM17/ to a host results directory, then run:\n"
        "python3 tools/script_args_compat_compare.py RESULTS_DIR\n\n"
        "Each case compares direct native EXECUTE against AmShell using identical\n"
        "script and outer argument text. No output normalization is expected.\n",
        encoding="ascii",
        newline="\n",
    )

    print(f"Prepared M1 script-argument qualification bundle in {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
