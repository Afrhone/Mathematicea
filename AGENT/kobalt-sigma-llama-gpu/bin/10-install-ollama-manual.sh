#!/usr/bin/env bash
set -euo pipefail

ARCH="${ARCH:-amd64}"
PREFIX="${PREFIX:-/usr}"
ROCM_TARBALL_URL="https://ollama.com/download/ollama-linux-${ARCH}-rocm.tar.zst"
BASE_TARBALL_URL="https://ollama.com/download/ollama-linux-${ARCH}.tar.zst"

echo "[ollama] installing base package into ${PREFIX}"
curl -fsSL "$BASE_TARBALL_URL" | tar --zstd -x -C "$PREFIX"

echo "[ollama] installing ROCm extension into ${PREFIX}"
curl -fsSL "$ROCM_TARBALL_URL" | tar --zstd -x -C "$PREFIX"

echo "[ollama] binary version"
/usr/bin/ollama -v || true
