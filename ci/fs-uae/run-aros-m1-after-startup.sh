#!/usr/bin/env bash
set -euo pipefail

# The base runner builds the qualification sequence by replacing AROS
# S:Startup-Sequence.  That is useful for staging, but running the tests before
# the normal AROS startup leaves Execute/CLI infrastructure incomplete.  Build
# a temporary runner which, after staging, turns that generated sequence into
# S:AmShell-CI and restores the original Startup-Sequence.  The qualification
# is then injected immediately before LoadWB (or appended as a fallback).
base="ci/fs-uae/run-aros-m1.sh"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 - "$base" "$tmp" <<'PY'
from pathlib import Path
import sys

src = Path(sys.argv[1]).read_text()
needle = 'config="$OUT/aros-m1.fs-uae"\n'
if needle not in src:
    raise SystemExit("ERROR: runner injection point not found")

block = r'''# Run the provisional qualification only after normal AROS startup has
# established assigns, handlers, libraries and Shell/Execute environment.
ci_script="$aros_root/S/AmShell-CI"
cp "$startup" "$ci_script"
# The old pre-startup runner chained to the original startup at the end.  Once
# the original startup owns boot sequencing that would recurse, so remove it.
sed -i '/^[[:space:]]*Execute[[:space:]]\+SYS:S\/Startup-Sequence\.amshell-original[[:space:]]*$/d' "$ci_script"
cp "$startup.amshell-original" "$startup"

# Insert before Workbench starts.  If this AROS image has no LoadWB line,
# append the qualification after the startup commands instead.
python3 - "$startup" <<'PY_STARTUP'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
lines = p.read_text(errors="surrogateescape").splitlines(True)
invoke = 'Execute SYS:S/AmShell-CI\n'
inserted = False
out = []
for line in lines:
    if not inserted and re.match(r'^\s*(?:SYS:C/)?LoadWB(?:\s|$)', line, re.I):
        out.append('; AmShell CI: run after core AROS startup, before Workbench\n')
        out.append(invoke)
        inserted = True
    out.append(line)
if not inserted:
    out.append('\n; AmShell CI: no LoadWB marker found; run after startup initialization\n')
    out.append(invoke)
p.write_text(''.join(out), errors="surrogateescape")
PY_STARTUP

# Preserve both sequences as evidence so future AROS image changes are visible.
cp "$startup" "$OUT/startup-sequence-patched.txt"
cp "$ci_script" "$OUT/amshell-ci-sequence.txt"

'''
Path(sys.argv[2]).write_text(src.replace(needle, block + needle, 1))
PY

chmod +x "$tmp"
bash "$tmp" "$@"
