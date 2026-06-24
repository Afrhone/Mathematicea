#!/usr/bin/env bash
set -euo pipefail
# Switch WG_CEPH_DIRECTIVE_FILE in .env quickly.
# Usage: ./bin/set-host.sh factau-rhiz|exosystem|eliosys-rhiz

host="${1:-}"
if [[ -z "$host" ]]; then
  echo "Usage: $0 factau-rhiz|exosystem|eliosys-rhiz" >&2
  exit 1
fi

ENV_FILE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env (copy env.example -> .env)" >&2
  exit 1
fi

case "$host" in
  factau-rhiz) f="directives/wg-ceph-operator.factau-rhiz.yaml" ;;
  exosystem) f="directives/wg-ceph-operator.exosystem.yaml" ;;
  eliosys-rhiz) f="directives/wg-ceph-operator.eliosys-rhiz.yaml" ;;
  *) echo "Unknown host: $host" >&2; exit 1 ;;
esac

tmp="$(mktemp)"
awk -v repl="WG_CEPH_DIRECTIVE_FILE=${f}" '
  BEGIN{done=0}
  /^WG_CEPH_DIRECTIVE_FILE=/{print repl; done=1; next}
  {print}
  END{ if(!done) print repl }
' "$ENV_FILE" > "$tmp"
mv "$tmp" "$ENV_FILE"
echo "Set WG_CEPH_DIRECTIVE_FILE=${f} in .env"
