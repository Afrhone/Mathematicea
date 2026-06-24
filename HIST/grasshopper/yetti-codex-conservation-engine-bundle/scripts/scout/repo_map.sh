#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

REPO="${1:-.}"
[[ -d "$REPO" ]] || die "repo dir missing: $REPO"
ensure_dirs

OUT="$PACKET_ROOT/repo-map.md"
LATEST="$PACKET_ROOT/latest-repo-map.md"

{
  echo "# Repo Map"
  echo
  echo "repo: $REPO"
  echo "time: $(date -Is)"
  echo
  echo "## Git"
  git -C "$REPO" status --short 2>/dev/null || true
  git -C "$REPO" branch --show-current 2>/dev/null || true
  git -C "$REPO" log --oneline -5 2>/dev/null || true
  echo
  echo "## Important files"
  find "$REPO" -maxdepth 4 -type f \
    | grep -Ev 'node_modules|.git/|dist/|build/|target/|__pycache__|.next/|vendor/' \
    | grep -E '\.(js|jsx|ts|tsx|py|sh|yml|yaml|json|md|sol|dockerfile|Dockerfile|toml|env|conf|service)$|Dockerfile$|compose' \
    | head -n "$MAX_FILE_LIST"
  echo
  echo "## Compose/Docker"
  find "$REPO" -maxdepth 4 -type f \( -iname '*compose*.yml' -o -iname '*compose*.yaml' -o -iname 'Dockerfile' -o -iname '*Dockerfile*' \) 2>/dev/null | head -50
  echo
  echo "## Package hints"
  find "$REPO" -maxdepth 4 -type f \( -iname 'package.json' -o -iname 'pyproject.toml' -o -iname 'requirements.txt' -o -iname 'Cargo.toml' -o -iname 'hardhat.config.js' \) 2>/dev/null | head -50
} > "$OUT"

cp "$OUT" "$LATEST"
sink_event "repo-map" "{\"repo\":\"$REPO\",\"out\":\"$OUT\"}"
echo "$OUT"
