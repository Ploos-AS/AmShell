#!/usr/bin/env bash
set -euo pipefail

# Build the provisional AROS qualification with normal system startup first,
# then run AmShell before the GUI shell takes over.
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

block = r'''ci_script="$aros_root/S/AmShell-CI"
cp "$startup" "$ci_script"
sed -i '/^[[:space:]]*Execute[[:space:]]\+SYS:S\/Startup-Sequence\.amshell-original[[:space:]]*$/d' "$ci_script"
cp "$startup.amshell-original" "$startup"

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
skip_bluetooth = False
out.append('C:Echo "startup-enter" >SYS:amshell-ci-boot-enter.txt\n')
for lineno, line in enumerate(lines, 1):
    stripped = line.strip()

    # The hosted image blocks while evaluating/initializing its optional
    # Bluetooth startup block. Bluetooth is unrelated to shell qualification,
    # so omit the complete guarded block only in this CI boot copy.
    if not skip_bluetooth and re.match(r'^If\s+EXISTS\s+["\']?SYS:Classes/Bluetooth["\']?\s*$', stripped, re.I):
        step += 1
        label = re.sub(r'[^A-Za-z0-9_.:-]+', '_', stripped)[:72]
        out.append(f'C:Echo "step={step} line={lineno} cmd={label}" >SYS:amshell-ci-boot-step-{step:03d}.txt\n')
        out.append('C:Echo "skipped Bluetooth startup block for hosted CI" >SYS:amshell-ci-bluetooth-skipped.txt\n')
        skip_bluetooth = True
        continue
    if skip_bluetooth:
        if re.match(r'^EndIf\s*$', stripped, re.I):
            skip_bluetooth = False
        continue

    if stripped and not stripped.startswith(';'):
        step += 1
        label = re.sub(r'[^A-Za-z0-9_.:-]+', '_', stripped)[:72]
        out.append(f'C:Echo "step={step} line={lineno} cmd={label}" >SYS:amshell-ci-boot-step-{step:03d}.txt\n')

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
if skip_bluetooth:
    raise SystemExit('ERROR: unterminated Bluetooth startup block')
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
  amshell-ci-bluetooth-skipped.txt \
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
