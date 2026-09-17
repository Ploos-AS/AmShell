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
sed -i '/^[[:space:]]*Execute[[:space:]]\+SYS:S\/Startup-Sequence\.amshell-original[[:space:]]*$/d' "$ci_script"
cp "$startup.amshell-original" "$startup"

# SetClock LOAD is hardware/RTC initialization and blocks indefinitely in the
# hosted FS-UAE AROS environment. It is irrelevant to shell qualification, so
# skip only this command in the CI copy of Startup-Sequence. Preserve a marker
# proving that the CI-specific bypass was taken.
python3 - "$startup" <<'PY_STARTUP'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
lines = p.read_text(errors="surrogateescape").splitlines(True)
invoke = 'C:Echo "reached-ci-hook" >SYS:amshell-ci-boot-hook.txt\nC:Execute SYS:S/AmShell-CI\n'
inserted = False
out = []
step = 0
out.append('C:Echo "startup-enter" >SYS:amshell-ci-boot-enter.txt\n')
for lineno, line in enumerate(lines, 1):
    stripped = line.strip()
    if stripped and not stripped.startswith(';'):
        step += 1
        label = re.sub(r'[^A-Za-z0-9_.:-]+', '_', stripped)[:72]
        out.append(f'C:Echo "step={step} line={lineno} cmd={label}" >SYS:amshell-ci-boot-step-{step:03d}.txt\n')

    # Hosted-CI exception: SetClock LOAD blocks on this virtual machine before
    # the command environment needed by the qualification has initialized.
    if re.match(r'^(?:SYS:C/|C:)?SetClock\s+LOAD\s*$', stripped, re.I):
        out.append('C:Echo "skipped SetClock LOAD for hosted CI" >SYS:amshell-ci-setclock-skipped.txt\n')
        continue

    if re.match(r'^If\s+EXISTS\s+["\']?S:User-Startup["\']?(?:\s|$)', stripped, re.I):
        out.append('C:Echo "before-user-startup" >SYS:amshell-ci-before-user-startup.txt\n')
    if re.match(r'^Execute\s+["\']?S:User-Startup["\']?(?:\s|$)', stripped, re.I):
        out.append(line)
        out.append('C:Echo "after-user-startup" >SYS:amshell-ci-after-user-startup.txt\n')
        continue
    wanderer_guard = re.match(r'^\s*If\s+EXISTS\s+["\']?WANDERER:Wanderer["\']?(?:\s|$)', line, re.I)
    gui_launch = (re.match(r'^\s*(?:SYS:C/)?LoadWB(?:\s|$)', line, re.I) or re.match(r'^\s*(?:WANDERER:)?Wanderer(?:\s|$)', line, re.I))
    if not inserted and (wanderer_guard or gui_launch):
        out.append('; AmShell CI: run after core AROS startup, before GUI shell guard\n')
        out.append(invoke)
        inserted = True
    out.append(line)
if not inserted:
    raise SystemExit('ERROR: no LoadWB/Wanderer launch point found in AROS Startup-Sequence')
p.write_text(''.join(out), errors="surrogateescape")
PY_STARTUP

cp "$startup" "$OUT/startup-sequence-patched.txt"
cp "$ci_script" "$OUT/amshell-ci-sequence.txt"

'''

postneedle = 'guest_rc=""; [[ -f "$aros_root/amshell-ci-rc.txt" ]]'
postblock = r'''for f in \
  amshell-ci-boot-enter.txt \
  amshell-ci-setclock-skipped.txt \
  amshell-ci-before-user-startup.txt \
  amshell-ci-after-user-startup.txt \
  amshell-ci-boot-hook.txt \
  amshell-ci-started.txt; do
  cp "$aros_root/$f" "$OUT/$f" 2>/dev/null || true
done
for f in "$aros_root"/amshell-ci-boot-step-*.txt; do
  [[ -f "$f" ]] || continue
  cp "$f" "$OUT/" 2>/dev/null || true
done
'''
if postneedle not in src:
    raise SystemExit("ERROR: guest result collection point not found")
src = src.replace(needle, block + needle, 1)
src = src.replace(postneedle, postblock + postneedle, 1)
Path(sys.argv[2]).write_text(src)
PY

chmod +x "$tmp"
bash "$tmp" "$@"
