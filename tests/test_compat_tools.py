#!/usr/bin/env python3
"""Host-side smoke tests for the M1.4 differential harness."""

from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PREPARE = ROOT / "tools" / "compat_prepare.py"
COMPARE = ROOT / "tools" / "compat_compare.py"
BUNDLE = ROOT / "tools" / "compat_bundle.py"
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
        native_runner = (out / "run-native.script").read_text(encoding="utf-8")
        if "CompatNative cases/native-001.script T:AmShellCompat/native-001.out" not in native_runner:
            print("FAIL: native runner does not use the native capture launcher")
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

        manifest.write_text("001\tAvail\n", encoding="utf-8")
        (results / "native-001.rc").write_text("0\n", encoding="latin-1")
        (results / "amshell-001.rc").write_text("0\n", encoding="latin-1")
        (results / "native-001.out").write_text(
            "Type Available In-Use Maximum Largest\n"
            "chip 900 100 1000 800\nfast 1800 200 2000 1700\n"
            "total 2700 300 3000 1700\n",
            encoding="latin-1",
        )
        (results / "amshell-001.out").write_text(
            "Type Available In-Use Maximum Largest\n"
            "chip 850 150 1000 750\nfast 1750 250 2000 1650\n"
            "total 2600 400 3000 1650\n",
            encoding="latin-1",
        )
        volatile = run(str(COMPARE), str(results), "--manifest", str(manifest))
        if volatile.returncode != 0 or "RESULT: PASS" not in volatile.stdout:
            print(volatile.stdout)
            return 1

        (results / "amshell-001.out").write_text(
            "Type Available In-Use Maximum Largest\n"
            "chip 850 150 1000 750\nfast 1750 250 2100 1650\n"
            "total 2600 400 3100 1650\n",
            encoding="latin-1",
        )
        stable_difference = run(
            str(COMPARE), str(results), "--manifest", str(manifest)
        )
        if (
            stable_difference.returncode == 0
            or "RESULT: FAIL" not in stable_difference.stdout
        ):
            print(stable_difference.stdout)
            return 1

        bundle = Path(tmp) / "bundle"
        bundled = run(str(BUNDLE), "--out", str(bundle))
        if bundled.returncode != 0:
            print(bundled.stdout)
            return 1
        candidate_runner = (bundle / "compat" / "run-amshell.script").read_text(
            encoding="utf-8"
        )
        if "/AmShell -c " not in candidate_runner:
            print("FAIL: bundled candidate runner cannot address the bundle binary")
            return 1
        native_runner = (bundle / "compat" / "run-native.script").read_text(
            encoding="utf-8"
        )
        if "/CompatNative cases/native-001.script " not in native_runner:
            print("FAIL: bundled native runner cannot address the capture launcher")
            return 1
        for script in (
            bundle / "run-qualification.script",
            bundle / "compat" / "run-native.script",
            bundle / "compat" / "run-amshell.script",
        ):
            if "2>NIL:" in script.read_text(encoding="utf-8"):
                print("FAIL: bundle contains non-AmigaDOS numbered redirection")
                return 1
    print("PASS: AmShell M1.4 compatibility harness smoke tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
