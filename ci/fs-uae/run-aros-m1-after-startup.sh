#!/usr/bin/env bash
set -euo pipefail

# The base runner builds the qualification sequence by replacing AROS
# S:Startup-Sequence. That is useful for staging, but running the tests before
# the normal AROS startup leaves Execute/CLI infrastructure incomplete. Build
# a temporary runner which, after staging, turns that generated sequence into
# S:AmShell-CI and restores the original Startup-Sequence. The qualification
# is then injected after normal startup initialization but before the GUI shell
# takes over the startup sequence.
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
# The old pre-startup runner chained to the original startup at the end. Once
# the original startup owns boot sequencing that would recurse, so remove it.
sed -i '/^[[:space:]]*Execute[[:space:]]\+SYS:S\/Startup-Sequence\.amshell-original[[:space:]]*$/d' "$ci_script"
cp "$startup.amshell-original" "$startup"

# AROS uses Wanderer rather than LoadWB in this image. The GUI launch is often
# guarded by `If EXISTS WANDERER:Wanderer`. Injecting immediately before the
# Wanderer command itself would put the qualification inside that conditional,
# so if the deferred WANDERER: assign does not resolve at this point the CI
# script is skipped entirely. Insert before the surrounding Wanderer EXISTS
# guard when present; otherwise fall back to a direct LoadWB/Wanderer launch.
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
    wanderer_guard = re.match(
        r'^\s*If\s+EXISTS\s+["\']?WANDERER:Wanderer["\']?(?:\s|$)',
        line,
        re.I,
    )
    gui_launch = (
        re.match(r'^\s*(?:SYS:C/)?LoadWB(?:\s|$)', line, re.I)
        or re.match(r'^\s*(?:WANDERER:)?Wanderer(?:\s|$)', line, re.I)
    )
    if not inserted and (wanderer_guard or gui_launch):
        out.append('; AmShell CI: run after core AROS startup, before GUI shell guard\n')
        out.append(invoke)
        inserted = True
    out.append(line)
if not inserted:
    raise SystemExit('ERROR: no LoadWB/Wanderer launch point found in AROS Startup-Sequence')
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
