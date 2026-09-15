#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-build/fs-uae/aros-m1}"
SYSTEM="build/fs-uae/aros-system"
mkdir -p "$OUT"

[[ -d build/m1-final-qualification ]] || { echo "ERROR: M1 final bundle missing" >&2; exit 1; }

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM" | tail -n1)"
root="$OUT/system-root"
rm -rf "$root"
mkdir -p "$root"
7z x -y -o"$root" "$iso" >/dev/null
startup="$(find "$root" -type f -ipath '*/s/startup-sequence' -print -quit)"
[[ -n "$startup" ]] || { echo "ERROR: AROS ISO lacks S/Startup-Sequence" >&2; exit 1; }
aros_root="$(dirname "$(dirname "$startup")")"

rm -rf "$aros_root/qualification" "$aros_root/qualification-results"
cp -a build/m1-final-qualification "$aros_root/qualification"
cp "$startup" "$startup.amshell-original"

# Normal AmigaOS qualification uses T:. Hosted CI needs evidence to survive the
# emulator timeout, so rewrite only the staged guest copy to persistent SYS:.
while IFS= read -r -d '' script; do
  sed -i \
    -e 's#T:AmShellCompat#SYS:qualification-results/m1.5#g' \
    -e 's#T:AmShellM16#SYS:qualification-results/m1.6#g' \
    -e 's#T:AmShellM17#SYS:qualification-results/m1.7-m1.9#g' \
    "$script"
done < <(find "$aros_root/qualification" -type f -name '*.script' -print0)

if grep -R -n -E 'T:AmShell(Compat|M16|M17)' "$aros_root/qualification" --include='*.script'; then
  echo "ERROR: transient qualification evidence path remained after CI rewrite" >&2
  exit 1
fi

# AROS has proven unreliable when a qualification command file is launched via
# Execute. Build one flat Startup-Sequence instead. Local harnesses carry their
# own FailAt values, but once flattened those would override the CI-wide policy
# and RC 20 negative cases could abort the complete run. Strip only FailAt lines
# while appending; the hosted guest remains under the single FailAt 21 below.
append_flat_script() {
  sed '/^[[:space:]]*FailAt[[:space:]]/d' "$1" >>"$startup"
}

cat >"$startup" <<'EOF'
FailAt 21
SYS:C/Echo "AMSHELL_CI_GUEST_STARTED=1" >SYS:amshell-ci-started.txt
SYS:C/Echo "startup" >SYS:amshell-ci-stage.txt

; The hosted qualification replaces AROS' normal Startup-Sequence and therefore
; runs before the distribution has installed its normal command search path.
; AmigaDOS commands such as Echo, Version, Avail, Assign, Type and Delete are
; intentionally submitted without a C: prefix by the compatibility corpus.
; Install SYS:C in the path first so those commands exercise the shell instead
; of failing with RETURN_ERROR merely because CI intercepted startup too early.
SYS:C/Path SYS:C ADD
SYS:C/Path >SYS:amshell-ci-path.txt
SYS:C/Echo "command-path-ready" >SYS:amshell-ci-stage.txt

SYS:C/MakeDir SYS:qualification-results >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.5 >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.6 >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.7-m1.9 >NIL:
SYS:C/Echo "persistent-results-ready" >SYS:amshell-ci-stage.txt
SYS:C/Echo "start" >SYS:amshell-m1-stage.txt

SYS:C/Echo "m1.5" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.5
Delete SYS:qualification-results/m1.5 ALL QUIET >NIL:
MakeDir SYS:qualification-results/m1.5 >NIL:
CD compat
EOF
append_flat_script "$aros_root/qualification/m1.5/compat/run-native.script"
append_flat_script "$aros_root/qualification/m1.5/compat/run-amshell.script"
cat >>"$startup" <<'EOF'
CD SYS:qualification/m1.5
SYS:C/Echo "m1.5-complete" >SYS:amshell-m1-stage.txt

SYS:C/Echo "m1.6" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.6
EOF
append_flat_script "$aros_root/qualification/m1.6/run-qualification.script"
cat >>"$startup" <<'EOF'
SYS:C/Echo "m1.6-complete" >SYS:amshell-m1-stage.txt

SYS:C/Echo "m1.7-m1.9" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.7-m1.9
EOF
append_flat_script "$aros_root/qualification/m1.7-m1.9/run-qualification.script"
cat >>"$startup" <<'EOF'
SYS:C/Echo "m1.7-m1.9-complete" >SYS:amshell-m1-stage.txt

SYS:C/Echo "m1.11" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.11
EOF
append_flat_script "$aros_root/qualification/m1.11/run-native-probe.script"
cat >>"$startup" <<'EOF'
SYS:C/Echo "m1.11-complete" >SYS:amshell-m1-stage.txt

CD SYS:qualification
SYS:C/Echo "complete" >SYS:amshell-m1-stage.txt
SYS:C/Echo "0" >SYS:amshell-ci-rc.txt
SYS:C/Echo "AMSHELL_CI_GUEST_RETURNED=1" >SYS:amshell-ci-returned.txt
SYS:C/Echo "qualification-returned" >SYS:amshell-ci-stage.txt

; Continue normal AROS startup after the qualification sequence.
Execute SYS:S/Startup-Sequence.amshell-original
EOF

# Hosted harness Execute calls must now only occur in test data/commands, not
# as wrappers around the qualification scripts themselves. Likewise there must
# be exactly one FailAt directive, the global FailAt 21 above.
if grep -n -E '^Execute (run-(qualification|native-probe)\.script|SYS:qualification/)' "$startup"; then
  echo "ERROR: qualification wrapper Execute remained in flat AROS startup" >&2
  exit 1
fi
if [[ "$(grep -c -E '^[[:space:]]*FailAt[[:space:]]+' "$startup")" != "1" ]] || \
   ! grep -q -E '^[[:space:]]*FailAt[[:space:]]+21[[:space:]]*$' "$startup"; then
  echo "ERROR: hosted AROS startup must contain only FailAt 21" >&2
  exit 1
fi

config="$OUT/aros-m1.fs-uae"
cat >"$config" <<EOF
[fs-uae]
amiga_model = A1200
kickstart_file = internal
hard_drive_0 = $PWD/$aros_root
fullscreen = 0
window_width = 640
window_height = 512
EOF

fs-uae --version >"$OUT/fs-uae-version.txt" 2>&1 || true
set +e
timeout 120s xvfb-run -a fs-uae "$config" >"$OUT/fs-uae.log" 2>&1
fs_rc=$?
set -e

status=FAIL
observation=guest_result_missing
guest_rc=""
if [[ -f "$aros_root/amshell-ci-rc.txt" ]]; then
  guest_rc="$(tr -d '\r\n ' < "$aros_root/amshell-ci-rc.txt")"
fi
if [[ -f "$aros_root/amshell-ci-returned.txt" && "$guest_rc" == "0" ]]; then
  status=PASS
  observation=combined_m1_guest_bundle_completed
elif [[ -n "$guest_rc" ]]; then
  observation="combined_m1_guest_rc_${guest_rc}"
fi

results="$OUT/results"
rm -rf "$results"
mkdir -p "$results/m1.5" "$results/m1.6" "$results/m1.7-m1.9" "$results/m1.11"
if [[ -d "$aros_root/qualification-results/m1.5" ]]; then
  cp -a "$aros_root/qualification-results/m1.5/." "$results/m1.5/"
fi
if [[ -d "$aros_root/qualification-results/m1.6" ]]; then
  cp -a "$aros_root/qualification-results/m1.6/." "$results/m1.6/"
fi
if [[ -d "$aros_root/qualification-results/m1.7-m1.9" ]]; then
  cp -a "$aros_root/qualification-results/m1.7-m1.9/." "$results/m1.7-m1.9/"
fi
cp -a "$aros_root/qualification/m1.11"/native-* "$results/m1.11/" 2>/dev/null || true
cp "$aros_root/amshell-ci-rc.txt" "$OUT/guest-rc.txt" 2>/dev/null || true
cp "$aros_root/amshell-ci-stage.txt" "$OUT/guest-stage.txt" 2>/dev/null || true
cp "$aros_root/amshell-m1-stage.txt" "$OUT/m1-stage.txt" 2>/dev/null || true
cp "$aros_root/amshell-ci-path.txt" "$OUT/guest-path.txt" 2>/dev/null || true

# Inventory is useful even on comparator failure: it distinguishes missing
# guest evidence from a real semantic mismatch.
find "$aros_root/qualification-results" -maxdepth 2 -type f -printf '%P\n' 2>/dev/null | sort >"$OUT/evidence-files.txt" || true

compare_status=NOT_RUN
if [[ "$status" == PASS ]]; then
  compare_status=PASS
  python3 tools/compat_compare.py "$results/m1.5" --manifest build/m1-final-qualification/m1.5/compat/manifest.txt | tee "$OUT/m1.5-compare.txt" || compare_status=FAIL
  python3 tools/script_compat_compare.py "$results/m1.6" | tee "$OUT/m1.6-compare.txt" || compare_status=FAIL
  python3 tools/script_args_compat_compare.py "$results/m1.7-m1.9" | tee "$OUT/m1.7-m1.9-compare.txt" || compare_status=FAIL
fi

{
  echo "STATUS=$status"
  echo "COMPARE_STATUS=$compare_status"
  echo "GATE=AROS_M1_COMBINED_RUNTIME"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "QUALIFICATION=provisional-ci-only"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "OBSERVATION=$observation"
  if [[ -f "$OUT/guest-stage.txt" ]]; then
    echo "GUEST_STAGE=$(tr -d '\r\n' < "$OUT/guest-stage.txt")"
  fi
  if [[ -n "$guest_rc" ]]; then
    echo "GUEST_RC=$guest_rc"
  fi
  if [[ -f "$OUT/m1-stage.txt" ]]; then
    echo "M1_STAGE=$(tr -d '\r\n' < "$OUT/m1-stage.txt")"
  fi
  echo "EVIDENCE_FILES=$(wc -l < "$OUT/evidence-files.txt" 2>/dev/null || echo 0)"
} | tee "$OUT/result.txt"

[[ "$status" == PASS && "$compare_status" == PASS ]]
