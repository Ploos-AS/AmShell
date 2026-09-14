#!/usr/bin/env python3
"""Build the deferred M1.11 native implied-CD precedence probe bundle."""

from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "m1.11-qualification"
CORPUS = ROOT / "tests" / "compat" / "implied_cd_cases.tsv"


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for name in ("AmShell", "CompatNative"):
        src = ROOT / "build" / name
        if not src.is_file():
            raise SystemExit(f"missing {src}; build first")
        shutil.copy2(src, OUT / name)
    shutil.copy2(CORPUS, OUT / CORPUS.name)

    script = [
        "; AmShell M1.11 native implied-CD precedence probe",
        "FailAt 20",
        "MakeDir RAM:AmShellM111 >NIL:",
        "CD RAM:AmShellM111",
        "MakeDir ProbeDir >NIL:",
        "MakeDir ProbeBoth >NIL:",
        "MakeDir RAM:ProbePath >NIL:",
        "; Create command files with the same names used by collision probes",
        'Echo "Echo command-ProbeCmd" >ProbeCmd',
        'Echo "Echo command-ProbeBoth" >ProbeBoth',
        "Protect ProbeCmd +e",
        "Protect ProbeBoth +e",
        "Path ADD RAM:AmShellM111",
        "; Native reference: each token is run through CompatNative exactly",
        'Echo "ProbeDir" >native-bare-dir-only.txt',
        'CompatNative native-bare-dir-only.txt native-bare-dir-only.out',
        'Echo $RC >native-bare-dir-only.rc',
        'CD >native-bare-dir-only.cwd',
        "CD RAM:AmShellM111",
        'Echo "ProbeCmd" >native-bare-command-only.txt',
        'CompatNative native-bare-command-only.txt native-bare-command-only.out',
        'Echo $RC >native-bare-command-only.rc',
        'CD >native-bare-command-only.cwd',
        "CD RAM:AmShellM111",
        'Echo "ProbeBoth" >native-bare-collision.txt',
        'CompatNative native-bare-collision.txt native-bare-collision.out',
        'Echo $RC >native-bare-collision.rc',
        'CD >native-bare-collision.cwd',
        "CD RAM:AmShellM111",
        'Echo "RAM:ProbePath" >native-pathlike-dir.txt',
        'CompatNative native-pathlike-dir.txt native-pathlike-dir.out',
        'Echo $RC >native-pathlike-dir.rc',
        'CD >native-pathlike-dir.cwd',
        "; Candidate interactive semantics are deferred to combined M1 qualification.",
        'Echo M1.11 native precedence probe complete',
    ]
    (OUT / "run-native-probe.script").write_text("\n".join(script) + "\n", encoding="ascii", newline="\n")
    (OUT / "README.txt").write_text(
        "AmShell M1.11 implied-CD precedence probe\n\n"
        "Run on visible AmigaOS 2.04 before changing bare-name implied-CD behavior.\n"
        "Execute run-native-probe.script\n\n"
        "Record stdout, RC, and resulting CD for bare directory-only, command-only,\n"
        "and command/directory collision cases. The native result is authoritative.\n"
        "Do not infer or mark M1.11 PASS from host tests alone.\n",
        encoding="ascii", newline="\n"
    )
    print(f"Prepared M1.11 precedence probe in {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
