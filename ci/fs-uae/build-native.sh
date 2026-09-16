#!/usr/bin/env bash
set -euo pipefail

IMAGE="${AMSHELL_BEBBO_IMAGE:-amigadev/m68k-amigaos-gcc@sha256:b18080e6ffca8f793e0f539536a9138e9d2a548ca1a301c7483f43ee15fedfed}"
OUT="${1:-build/fs-uae/native}"
mkdir -p "$OUT" build

docker pull "$IMAGE"
docker image inspect "$IMAGE" --format '{{join .RepoDigests "\n"}}' | tee "$OUT/toolchain-image.txt"

build_one() {
  local output="$1"
  shift
  docker run --rm -v "$PWD:/work" -w /work "$IMAGE" \
    m68k-amigaos-gcc -Os -Wall -Wextra -Werror -m68000 -o "$output" "$@"
}

build_one build/AmShell src/main.c src/exec.c src/session.c
build_one build/CompatNative tools/compat_native.c
build_one build/ArosCaptureProbe tools/aros_capture_probe.c

cp build/AmShell "$OUT/AmShell"
cp build/CompatNative "$OUT/CompatNative"
cp build/ArosCaptureProbe "$OUT/ArosCaptureProbe"
file "$OUT/AmShell" "$OUT/CompatNative" "$OUT/ArosCaptureProbe" | tee "$OUT/file.txt"
sha256sum "$OUT/AmShell" "$OUT/CompatNative" "$OUT/ArosCaptureProbe" | tee "$OUT/sha256.txt"

# Diagnostic only: compare the failing AmShell binary with the known-working
# ArosCaptureProbe at ELF/HUNK/link level. Keep this out of production flags.
{
  echo '=== sizes ==='
  wc -c "$OUT/AmShell" "$OUT/CompatNative" "$OUT/ArosCaptureProbe"
  echo '=== hunk/file identification ==='
  file "$OUT/AmShell" "$OUT/CompatNative" "$OUT/ArosCaptureProbe"
  echo '=== AmShell strings: runtime/library hints ==='
  strings "$OUT/AmShell" | grep -Ei 'library|dos|ixemul|libnix|stdio|startup|stack|SystemTagList|CurrentDir|MatchFirst' || true
  echo '=== ArosCaptureProbe strings: runtime/library hints ==='
  strings "$OUT/ArosCaptureProbe" | grep -Ei 'library|dos|ixemul|libnix|stdio|startup|stack|SystemTagList|CurrentDir|MatchFirst' || true
  echo '=== CompatNative strings: runtime/library hints ==='
  strings "$OUT/CompatNative" | grep -Ei 'library|dos|ixemul|libnix|stdio|startup|stack|SystemTagList|CurrentDir|MatchFirst' || true
} >"$OUT/binary-compare.txt"
cat "$OUT/binary-compare.txt"

python3 tools/m1_final_bundle.py

printf 'STATUS=PASS\nGATE=NATIVE_BEBBO_BUILD\nIMAGE=%s\n' "$IMAGE" | tee "$OUT/result.txt"
