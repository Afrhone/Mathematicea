#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/exports/nano-media"
mkdir -p "$OUT"
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg missing. Install with: brew install ffmpeg"
  exit 2
fi
# Creates a small video placeholder from spectrogram snapshots. Replace PNGs with your own capture sequence.
python3 "$ROOT/scripts/make-demo-frames.py" "$OUT/frames"
ffmpeg -y -framerate 12 -i "$OUT/frames/frame_%04d.png" -vf "scale=320:-2" -pix_fmt yuv420p "$OUT/nano_spectrogram_320.mp4"
ffmpeg -y -i "$OUT/nano_spectrogram_320.mp4" -vf "fps=10,scale=240:-1:flags=lanczos" "$OUT/nano_spectrogram.gif"
echo "Exported nano media assets to $OUT"
