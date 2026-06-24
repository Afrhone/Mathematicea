#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p /opt/rhiz-imported-bundles
for z in "$ROOT"/vendor/imported-bundles/*.zip; do
  [ -f "$z" ] || continue
  name="$(basename "$z" .zip)"
  mkdir -p "/opt/rhiz-imported-bundles/$name"
  unzip -oq "$z" -d "/opt/rhiz-imported-bundles/$name"
  echo "imported $z -> /opt/rhiz-imported-bundles/$name"
done
