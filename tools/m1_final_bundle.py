#!/usr/bin/env python3
"""Build the combined AmShell M1 final qualification bundle.

This packages the already-qualified M1.5/M1.6 regressions together with the
M1.7/M1.9 script-argument surface and the M1.11 native implied-CD precedence
probe.  It deliberately does not claim runtime PASS; visible guest evidence is
required, and M1.11 precedence must be interpreted before M1 can be frozen.
"""

from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
OUT = BUILD / "m1-final-qualification"


def run_tool(*args: str) -> None:
    subprocess.run(["python3", *args], cwd=ROOT, check=True)


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def main() -> int:
    for name in ("AmShell", "CompatNative"):
        if not (BUILD / name).is_file():
            raise SystemExit(f"missing {BUILD / name}; build first")

    # Build each established qualification package with its existing tool so
    # the final bundle cannot silently diverge from the standalone harnesses.
    run_tool(
        str(ROOT / "tools" / "compat_bundle.py"),
        "--out", str(BUILD / "m1.5-final-stage"),
        "--amshell", "../AmShell",
        "--native-launcher", "../CompatNative",
    )
    run_tool(str(ROOT / "tools" / "script_compat_bundle.py"))
    run_tool(str(ROOT / "tools" / "script_args_compat_bundle.py"))
    run_tool(str(ROOT / "tools" / "implied_cd_probe_bundle.py"))

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    shutil.copy2(BUILD / "AmShell", OUT / "AmShell")
    shutil.copy2(BUILD / "CompatNative", OUT / "CompatNative")

    copy_tree(BUILD / "m1.5-final-stage", OUT / "m1.5")
    copy_tree(BUILD / "m1.6-qualification", OUT / "m1.6")
    copy_tree(BUILD / "m1.7-qualification", OUT / "m1.7-m1.9")
    copy_tree(BUILD / "m1.11-qualification", OUT / "m1.11")

    # Use one top-level guest script.  Each sub-harness keeps its own result
    # namespace (T:AmShellCompat, T:AmShellM16, T:AmShellM17, plus M1.11 files).
    guest = [
        "; AmShell M1 combined visible-FS-UAE qualification",
        "; Baseline: A500/68000 + AmigaOS 2.04",
        "FailAt 20",
        'Echo "=== AmShell M1 final qualification starting ==="',
        "CD m1.5",
        "Execute run-qualification.script",
        "CD /",
        "CD m1.6",
        "Execute run-qualification.script",
        "CD /",
        "CD m1.7-m1.9",
        "Execute run-qualification.script",
        "CD /",
        "CD m1.11",
        "Execute run-native-probe.script",
        "CD /",
        'Echo "=== M1 guest execution complete ==="',
        'Echo "Collect T:AmShellCompat, T:AmShellM16, T:AmShellM17 and m1.11/native-* evidence."',
    ]
    (OUT / "run-m1-final.script").write_text(
        "\n".join(guest) + "\n", encoding="ascii", newline="\n"
    )

    readme = """AmShell M1 combined final qualification bundle

Status before guest execution: PENDING

Target baseline:
- visible FS-UAE
- A500 / 68000
- Kickstart + Workbench 2.04

Guest procedure:
1. Copy this whole directory to an Amiga filesystem.
2. Make this directory current.
3. Run: Execute run-m1-final.script
4. Preserve all produced evidence before modifying AmShell.

Evidence to collect:
- T:AmShellCompat/        (M1.5 command differential regression)
- T:AmShellM16/           (M1.6 command-file regression)
- T:AmShellM17/           (M1.7/M1.9 argument and .KEY surface)
- m1.11/native-*.out/.rc/.cwd (native bare-name implied-CD precedence probe)

Host comparison:
- M1.5: python3 tools/compat_compare.py RESULTS_M15 --manifest build/m1-final-qualification/m1.5/compat/manifest.txt
- M1.6: python3 tools/script_compat_compare.py RESULTS_M16
- M1.7/M1.9: python3 tools/script_args_compat_compare.py RESULTS_M17

M1.11 is intentionally a native semantics probe, not an automatic PASS.  Its
stdout, RC and cwd evidence decides whether bare-name implied CD needs a code
change.  If code changes after interpreting the probe, rerun this complete
bundle before declaring M1 PASS.
"""
    (OUT / "README.txt").write_text(readme, encoding="ascii", newline="\n")

    print(f"Prepared combined M1 qualification bundle in {OUT}")
    print("Runtime verdict: PENDING")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
