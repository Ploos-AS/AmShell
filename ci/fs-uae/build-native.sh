#!/usr/bin/env bash
set -euo pipefail

IMAGE="${AMSHELL_BEBBO_IMAGE:-amigadev/m68k-amigaos-gcc@sha256:b18080e6ffca8f793e0f539536a9138e9d2a548ca1a301c7483f43ee15fedfed}"
OUT="${1:-build/fs-uae/native}"
mkdir -p "$OUT" build

docker pull "$IMAGE"
docker image inspect "$IMAGE" --format '{{join .RepoDigests "\n"}}' | tee "$OUT/toolchain-image.txt"

docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  "$IMAGE" \
  m68k-amigaos-gcc \
    -Os -Wall -Wextra -Werror -m68000 \
    -o build/AmShell \
    src/main.c src/exec.c src/session.c

docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  "$IMAGE" \
  m68k-amigaos-gcc \
    -Os -Wall -Wextra -Werror -m68000 \
    -o build/CompatNative \
    tools/compat_native.c

cp build/AmShell "$OUT/AmShell"
cp build/CompatNative "$OUT/CompatNative"
file "$OUT/AmShell" "$OUT/CompatNative" | tee "$OUT/file.txt"
sha256sum "$OUT/AmShell" "$OUT/CompatNative" | tee "$OUT/sha256.txt"

python3 tools/m1_final_bundle.py

printf 'STATUS=PASS\nGATE=NATIVE_BEBBO_BUILD\nIMAGE=%s\n' "$IMAGE" | tee "$OUT/result.txt"
