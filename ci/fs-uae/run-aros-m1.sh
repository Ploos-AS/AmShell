#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-build/fs-uae/aros-m1}"
SYSTEM="build/fs-uae/aros-system"
mkdir -p "$OUT"
[[ -d build/m1-final-qualification ]] || { echo "ERROR: M1 final bundle missing" >&2; exit 1; }

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM" | tail -n1)"
root="$OUT/system-root"
rm -rf "$root" && mkdir -p "$root"
7z x -y -o"$root" "$iso" >/dev/null
startup="$(find "$root" -type f -ipath '*/s/startup-sequence' -print -quit)"
[[ -n "$startup" ]] || { echo "ERROR: AROS ISO lacks S/Startup-Sequence" >&2; exit 1; }
aros_root="$(dirname "$(dirname "$startup")")"
rm -rf "$aros_root/qualification" "$aros_root/qualification-results"
cp -a build/m1-final-qualification "$aros_root/qualification"
cp build/fs-uae/native/ArosCaptureProbe "$aros_root/qualification/ArosCaptureProbe"
cp "$startup" "$startup.amshell-original"

while IFS= read -r -d '' script; do
  sed -i -e 's#T:AmShellCompat#RAM:AmShellCompat#g' -e 's#T:AmShellM16#RAM:AmShellM16#g' -e 's#T:AmShellM17#RAM:AmShellM17#g' "$script"
done < <(find "$aros_root/qualification" -type f -name '*.script' -print0)
if grep -R -n -E 'T:AmShell(Compat|M16|M17)' "$aros_root/qualification" --include='*.script'; then exit 1; fi

# Hosted AROS is a provisional compatibility gate, not the authoritative
# AmigaOS 2.04 qualification.  Run its native reference directly through
# AROS C:Execute and capture at the outer Shell.  The CompatNative helper is
# retained unchanged in the portable/classic bundles because it is required
# there to avoid pre-V40 Execute capture limitations.  AROS' own capture probe
# verifies that Shell redirection works in this hosted environment.
sed -i \
  -e 's#^/CompatNative cases/\([^ ]*\) \(.*\)$#SYS:C/Execute SYS:qualification/m1.5/compat/cases/\1 >\2#' \
  -e 's#^/AmShell #SYS:qualification/m1.5/AmShell #' \
  "$aros_root/qualification/m1.5/compat/run-native.script" \
  "$aros_root/qualification/m1.5/compat/run-amshell.script"
sed -i \
  -e 's#^CompatNative native-command.txt \(.*\)$#SYS:C/Execute SYS:qualification/m1.6/native-command.txt >\1#' \
  -e 's#^AmShell #SYS:qualification/m1.6/AmShell #' \
  "$aros_root/qualification/m1.6/run-qualification.script"
sed -i \
  -e 's#^CompatNative commands/\([^ ]*\) \(.*\)$#SYS:C/Execute SYS:qualification/m1.7-m1.9/commands/\1 >\2#' \
  -e 's#^AmShell #SYS:qualification/m1.7-m1.9/AmShell #' \
  "$aros_root/qualification/m1.7-m1.9/run-qualification.script"

append_flat_script() { sed '/^[[:space:]]*FailAt[[:space:]]/d' "$1" >>"$startup"; }

cat >"$startup" <<'EOF'
FailAt 21
SYS:C/Echo "AMSHELL_CI_GUEST_STARTED=1" >SYS:amshell-ci-started.txt
SYS:C/Assign C: SYS:C
SYS:C/Path SYS:C ADD
Echo "unqualified-command-probe" >SYS:amshell-ci-command-probe.txt
SYS:C/Echo "$RC" >SYS:amshell-ci-command-probe.rc
SYS:qualification/ArosCaptureProbe
SYS:C/Echo "$RC" >SYS:amshell-capture-probe.rc
SYS:C/Copy RAM:amshell-probe-#? SYS: ALL QUIET
SYS:C/Echo "$RC" >SYS:amshell-capture-probe-copy.rc
SYS:C/MakeDir SYS:qualification-results >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.5 >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.6 >NIL:
SYS:C/MakeDir SYS:qualification-results/m1.7-m1.9 >NIL:
SYS:C/Echo "m1.5" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.5
Delete RAM:AmShellCompat ALL QUIET >NIL:
MakeDir RAM:AmShellCompat >NIL:
CD compat
EOF
append_flat_script "$aros_root/qualification/m1.5/compat/run-native.script"
append_flat_script "$aros_root/qualification/m1.5/compat/run-amshell.script"
cat >>"$startup" <<'EOF'
CD SYS:qualification/m1.5
SYS:C/Copy RAM:AmShellCompat SYS:qualification-results/m1.5 ALL QUIET
SYS:C/Echo "$RC" >SYS:amshell-ci-m1.5-copy.rc
SYS:C/Echo "m1.6" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.6
EOF
append_flat_script "$aros_root/qualification/m1.6/run-qualification.script"
cat >>"$startup" <<'EOF'
SYS:C/Copy RAM:AmShellM16 SYS:qualification-results/m1.6 ALL QUIET
SYS:C/Echo "$RC" >SYS:amshell-ci-m1.6-copy.rc
SYS:C/Echo "m1.7-m1.9" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.7-m1.9
EOF
append_flat_script "$aros_root/qualification/m1.7-m1.9/run-qualification.script"
cat >>"$startup" <<'EOF'
SYS:C/Copy RAM:AmShellM17 SYS:qualification-results/m1.7-m1.9 ALL QUIET
SYS:C/Echo "$RC" >SYS:amshell-ci-m1.7-copy.rc
SYS:C/Echo "m1.11" >SYS:amshell-m1-stage.txt
CD SYS:qualification/m1.11
EOF
append_flat_script "$aros_root/qualification/m1.11/run-native-probe.script"
cat >>"$startup" <<'EOF'
CD SYS:qualification
SYS:C/Echo "complete" >SYS:amshell-m1-stage.txt
SYS:C/Echo "0" >SYS:amshell-ci-rc.txt
SYS:C/Echo "AMSHELL_CI_GUEST_RETURNED=1" >SYS:amshell-ci-returned.txt
SYS:C/Echo "qualification-returned" >SYS:amshell-ci-stage.txt
Execute SYS:S/Startup-Sequence.amshell-original
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

guest_rc=""; [[ -f "$aros_root/amshell-ci-rc.txt" ]] && guest_rc="$(tr -d '\r\n ' < "$aros_root/amshell-ci-rc.txt")"
status=FAIL; observation=guest_result_missing
if [[ -f "$aros_root/amshell-ci-returned.txt" && "$guest_rc" == 0 ]]; then status=PASS; observation=combined_m1_guest_bundle_completed; fi
results="$OUT/results"; rm -rf "$results"; mkdir -p "$results"/{m1.5,m1.6,m1.7-m1.9,m1.11}
declare -A stage_dir=( [m1.5]=AmShellCompat [m1.6]=AmShellM16 [m1.7-m1.9]=AmShellM17 )
for stage in m1.5 m1.6 m1.7-m1.9; do
  src="$aros_root/qualification-results/$stage"
  [[ -d "$src" ]] || continue
  if [[ -d "$src/${stage_dir[$stage]}" ]]; then cp -a "$src/${stage_dir[$stage]}/." "$results/$stage/"; else cp -a "$src/." "$results/$stage/"; fi
done
cp -a "$aros_root/qualification/m1.11"/native-* "$results/m1.11/" 2>/dev/null || true
for f in amshell-ci-rc.txt amshell-ci-stage.txt amshell-m1-stage.txt amshell-ci-command-probe.rc amshell-ci-m1.5-copy.rc amshell-ci-m1.6-copy.rc amshell-ci-m1.7-copy.rc amshell-capture-probe.rc amshell-capture-probe-copy.rc amshell-probe-direct.txt amshell-probe-redir.txt amshell-probe-redir.rc amshell-probe-sysout.txt amshell-probe-sysout.rc; do cp "$aros_root/$f" "$OUT/$f" 2>/dev/null || true; done
find "$aros_root/qualification-results" -maxdepth 3 -type f -printf '%P\n' 2>/dev/null | sort >"$OUT/evidence-files.txt" || true
compare_status=NOT_RUN
if [[ "$status" == PASS ]]; then
 compare_status=PASS
 python3 tools/compat_compare.py "$results/m1.5" --manifest build/m1-final-qualification/m1.5/compat/manifest.txt | tee "$OUT/m1.5-compare.txt" || compare_status=FAIL
 python3 tools/script_compat_compare.py "$results/m1.6" | tee "$OUT/m1.6-compare.txt" || compare_status=FAIL
 python3 tools/script_args_compat_compare.py "$results/m1.7-m1.9" | tee "$OUT/m1.7-m1.9-compare.txt" || compare_status=FAIL
fi
probe_state() { local f="$1"; if [[ -f "$OUT/$f" ]]; then printf '%s:%s' "$f" "$(wc -c < "$OUT/$f")"; else printf '%s:MISSING' "$f"; fi; }
{
 echo "STATUS=$status"; echo "COMPARE_STATUS=$compare_status"; echo "GATE=AROS_M1_COMBINED_RUNTIME"; echo "QUALIFICATION=provisional-ci-only"; echo "FS_UAE_EXIT=$fs_rc"; echo "OBSERVATION=$observation"; echo "GUEST_RC=$guest_rc"
 echo "CAPTURE_DIRECT=$(probe_state amshell-probe-direct.txt)"; echo "CAPTURE_REDIRECT=$(probe_state amshell-probe-redir.txt)"; echo "CAPTURE_SYSOUTPUT=$(probe_state amshell-probe-sysout.txt)"
 [[ -f "$OUT/amshell-probe-redir.rc" ]] && echo "CAPTURE_REDIRECT_RC=$(tr -d '\r\n ' < "$OUT/amshell-probe-redir.rc")"
 [[ -f "$OUT/amshell-probe-sysout.rc" ]] && echo "CAPTURE_SYSOUTPUT_RC=$(tr -d '\r\n ' < "$OUT/amshell-probe-sysout.rc")"
 echo "EVIDENCE_FILES=$(wc -l < "$OUT/evidence-files.txt" 2>/dev/null || echo 0)"
} | tee "$OUT/result.txt"
[[ "$status" == PASS && "$compare_status" == PASS ]]
