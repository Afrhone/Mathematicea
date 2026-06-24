#!/usr/bin/env bash
cd "$(dirname "$0")"
python3 -m http.server "${PORT:-8787}" --bind "${BIND:-0.0.0.0}"
