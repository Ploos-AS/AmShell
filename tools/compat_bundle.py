#!/usr/bin/env python3
"""Build a self-contained M1.5 AmigaOS differential qualification bundle.

The bundle contains the prepared native/AmShell command files, manifest,
Amiga-side runner, and collection instructions.  It deliberately does not
claim a runtime PASS; that requires execution on AmigaOS/FS-UAE.
"""

from pathlib import Path
import argparse
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=ROOT / "build" / "m1.5-qualification")
    parser.add_argument("--amshell", default="AmShell")
    parser.add_argument("--binary", type=Path, default=ROOT / "build" / "AmShell")
    args = parser.parse_args()

    if args.out.exists():
        shutil.rmtree(args.out)
    args.out.mkdir(parents=True)

    prepared = args.out / "compat"
    subprocess.run(
        [
            "python3",
            str(ROOT / "tools" / "compat_prepare.py"),
            "--out",
            str(prepared),
            "--amshell",
            args.amshell,
        ],
        check=True,
    )

    if args.binary.is_file():
        shutil.copy2(args.binary, args.out / "AmShell")
        binary_state = "included"
    else:
        binary_state = "not included; copy the built 68k AmShell binary into this directory before guest execution"

    runner = """; AmShell M1.5 differential qualification runner
; Run from the qualification bundle directory on AmigaOS.
FailAt 20
Echo "AmShell M1.5 qualification starting"
Delete T:AmShellCompat ALL QUIET >NIL: 2>NIL:
MakeDir T:AmShellCompat >NIL: 2>NIL:
CD compat
Execute run-native.script
Execute run-amshell.script
CD /
Echo "Guest run complete. Copy T:AmShellCompat back to the host for comparison."
"""
    (args.out / "run-qualification.script").write_text(runner, encoding="utf-8", newline="\n")

    readme = f"""# AmShell M1.5 qualification bundle

Binary: {binary_state}

Guest procedure:

1. Copy this whole directory to an AmigaOS 2.04+ filesystem accessible by the guest.
2. Ensure `AmShell` is on the command path, or present in the bundle and assigned appropriately.
3. From the bundle directory run `Execute run-qualification.script`.
4. Copy the complete contents of `T:AmShellCompat/` back to a host directory.
5. On the host run:

   python3 tools/compat_compare.py RESULTS_DIR --manifest build/m1.5-qualification/compat/manifest.txt

Only an all-case `RESULT: PASS` from the comparator counts as the M1.5 runtime verdict.
"""
    (args.out / "README.txt").write_text(readme, encoding="utf-8", newline="\n")

    print(f"Prepared M1.5 qualification bundle: {args.out}")
    print(f"AmShell binary: {binary_state}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
