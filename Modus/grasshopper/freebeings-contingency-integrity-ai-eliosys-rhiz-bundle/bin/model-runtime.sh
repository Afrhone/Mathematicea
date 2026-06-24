#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
cmd="${1:-help}"
MODEL="${EDGE_MODEL:-llama3.2:3b}"
OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"
export OLLAMA_HOST

install_ollama(){
  if command -v ollama >/dev/null 2>&1; then ollama --version; return 0; fi
  if [ "${ALLOW_NETWORK_INSTALL:-0}" != "1" ]; then
    warn "Set ALLOW_NETWORK_INSTALL=1 DRY_RUN=0 to run Ollama install script."
    exit 3
  fi
  run sh -c 'curl -fsSL https://ollama.com/install.sh | sh'
}

pull(){ run ollama pull "$MODEL"; }
serve(){ run systemctl enable --now ollama || run ollama serve; }
ask(){
  shift || true
  prompt="${*:-State your model identity and memory budget.}"
  ollama run "$MODEL" "$prompt"
}
health(){
  curl -fsS "$OLLAMA_HOST/api/tags" | jq . || true
  free -h || true
}
case "$cmd" in
  install-ollama) install_ollama ;;
  pull) pull ;;
  serve) serve ;;
  ask) ask "$@" ;;
  health) health ;;
  help|*) echo "usage: $0 install-ollama|pull|serve|ask|health" ;;
esac
