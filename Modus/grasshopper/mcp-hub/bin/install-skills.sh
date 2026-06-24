#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
DRY_RUN="${DRY_RUN:-${NIURK_DRY_RUN:-1}}"
cmds=(
  "npx skillfish add plurigrid/asi cognitive-superposition"
  "npx skillfish add lev-os/agents superforecasting"
  "npx skillfish add tondevrel/scientific-agent-skills scikit-image"
  "npx skillfish add bbeierle12/skill-mcp-claude particles-router"
)
for c in "${cmds[@]}"; do
  log "+ $c"
  if [[ "$DRY_RUN" != "1" ]]; then bash -lc "$c"; fi
done
log "skill registry source: config/skills.registry.yaml"
