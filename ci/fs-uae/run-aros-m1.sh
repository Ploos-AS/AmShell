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

rm -rf "$aros_root/qualification"
cp -a build/m1-final-qualification "$aros_root/qualification"
cp "$startup" "$startup.amshell-original"

cat >"$startup" <<'EOF'
FailAt 21
SYS:C/Echo "AMSHELL_CI_GUEST_STARTED=1" >SYS:amshell-ci-started.txt
SYS:C/Echo "startup" >SYS:amshell-ci-stage.txt
SYS:C/MakeDir SYS:qualification-results >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.5 >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.6 >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.7-m1.9 >NIL:
SYS:C/Echo "qualification-cd" >SYS:amshell-ci-stage.txt
CD SYS:qualification
SYS:C/Echo "qualification-execute" >SYS:amshell-ci-stage.txt
SYS:C/Execute run-m1-final.script >SYS:amshell-ci-console.txt
SYS:C/Echo $RC >SYS:amshell-ci-rc.txt
SYS:C/Copy T:AmShellM1Stage SYS:amshell-ci-m1-stage.txt QUIET
SYS:C/Echo "collect" >SYS:amshell-ci-stage.txt
SYS:C/Copy T:AmShellCompat/#? SYS:qualification-results/m1.5 ALL QUIET
SYS:C/Copy T:AmShellM16/#? SYS:qualification-results/m1.6 ALL QUIET
SYS:C/Copy T:AmShellM17/#? SYS:qualification-results/m1.7-m1.9 ALL QUIET
SYS:C/Echo "AMSHELL_CI_GUEST_COMPLETE=1" >SYS:amshell-ci-complete.txt
SYS:C/Echo "complete" >SYS:amshell-ci-stage.txt
SYS:C/Execute SYS:S/Startup-Sequence.amshell-original
EOF

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
if [[ -f "$aros_root/amshell-ci-complete.txt" ]]; then
  status=PASS
  observation=combined_m1_guest_bundle_completed
fi

results="$OUT/results"
rm -rf "$results"
mkdir -p "$results"
if [[ -d "$aros_root/qualification-results" ]]; then
  cp -a "$aros_root/qualification-results/." "$results/"
fi
mkdir -p "$results/m1.11"
cp -a "$aros_root/qualification/m1.11"/native-* "$results/m1.11/" 2>/dev/null || true
cp "$aros_root/amshell-ci-console.txt" "$OUT/guest-console.txt" 2>/dev/null || true
cp "$aros_root/amshell-ci-rc.txt" "$OUT/guest-rc.txt" 2>/dev/null || true
cp "$aros_root/amshell-ci-stage.txt" "$OUT/guest-stage.txt" 2>/dev/null || true
cp "$aros_root/amshell-ci-m1-stage.txt" "$OUT/m1-stage.txt" 2>/dev/null || true

compare_status=PASS
if [[ "$status" == PASS ]]; then
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
  if [[ -f "$OUT/m1-stage.txt" ]]; then
    echo "M1_STAGE=$(tr -d '\r\n' < "$OUT/m1-stage.txt")"
  fi
} | tee "$OUT/result.txt"

[[ "$status" == PASS && "$compare_status" == PASS ]]
