#!/usr/bin/env bash
set -euo pipefail

TAG="${LLAMA_CPP_TAG:-b3265}"
DEST="${DEST:-/opt/llama.cpp}"
BUILD_DIR="${BUILD_DIR:-$DEST/build}"
GPU_BACKEND="${GPU_BACKEND:-cuda}"

if ! command -v git >/dev/null 2>&1 || ! command -v cmake >/dev/null 2>&1; then
  echo "git/cmake missing. This path requires apt or equivalent package install first." >&2
  exit 1
fi

rm -rf "$DEST"
git clone --depth 1 --branch "$TAG" https://github.com/ggml-org/llama.cpp.git "$DEST"

case "$GPU_BACKEND" in
  cuda)
    cmake -S "$DEST" -B "$BUILD_DIR" -DGGML_CUDA=ON
    ;;
  rocm|hip)
    cmake -S "$DEST" -B "$BUILD_DIR" -DGGML_HIPBLAS=ON
    ;;
  cpu)
    cmake -S "$DEST" -B "$BUILD_DIR"
    ;;
  *)
    echo "unsupported GPU_BACKEND=$GPU_BACKEND" >&2
    exit 2
    ;;
esac

cmake --build "$BUILD_DIR" -j"$(nproc)"
"$BUILD_DIR/bin/llama-server" --help | sed -n '1,40p' || true
