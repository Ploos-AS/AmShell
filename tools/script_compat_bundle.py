#!/usr/bin/env python3
"""Build the M1.6 command-file runtime qualification package."""

from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "m1.6-qualification"


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)

    for name in ("AmShell", "CompatNative"):
        src = ROOT / "build" / name
        if not src.is_file():
            raise SystemExit(f"missing {src}; build first")
        shutil.copy2(src, OUT / name)

    shutil.copy2(ROOT / "tests" / "compat" / "scripts" / "basic.script", OUT / "basic.script")

    (OUT / "native-command.txt").write_text(
        "Execute basic.script\n", encoding="ascii", newline="\n"
    )

    (OUT / "run-qualification.script").write_text(
        "; AmShell M1.6 command-file differential qualification\n"
        "FailAt 20\n"
        "MakeDir T:AmShellM16 >NIL: 2>NIL:\n"
        "CompatNative native-command.txt T:AmShellM16/native-script.out\n"
        "Echo $RC >T:AmShellM16/native-script.rc\n"
        "AmShell basic.script >T:AmShellM16/amshell-script.out\n"
        "Echo $RC >T:AmShellM16/amshell-script.rc\n"
        "Echo M1.6 guest run complete\n",
        encoding="ascii",
        newline="\n",
    )

    (OUT / "README.txt").write_text(
        "AmShell M1.6 runtime qualification\n\n"
        "Run this directory as the current directory on visible FS-UAE/AmigaOS.\n"
        "Execute run-qualification.script\n\n"
        "Copy the four files from T:AmShellM16/ back to a host results directory.\n"
        "Then run:\n"
        "python3 tools/script_compat_compare.py RESULTS_DIR\n\n"
        "PASS requires equal RC and equivalent output after only the documented\n"
        "volatile AVAIL counters are normalized.\n",
        encoding="ascii",
        newline="\n",
    )

    print(f"Prepared M1.6 qualification bundle in {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
