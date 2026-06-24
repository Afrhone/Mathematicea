#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ENV_FILE="${ENV_FILE:-$ROOT/.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERR] Missing .env in $ROOT. Copy env/cluster.env to .env first." >&2
  exit 2
fi
source "$ENV_FILE"

log(){ printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33m[WARN] %s\033[0m\n' "$*" >&2; }
err(){ printf '\033[1;31m[ERR] %s\033[0m\n' "$*" >&2; }
run(){ echo "+ $*"; "$@"; }

normalize_image(){
  local img="${1:-images:ubuntu/24.04}"
  case "$img" in
    ubuntu:24.04|ubuntu:noble|ubuntu/24.04|24.04|noble)
      echo "images:ubuntu/24.04" ;;
    images:ubuntu:24.04)
      echo "images:ubuntu/24.04" ;;
    *)
      echo "$img" ;;
  esac
}

FIXED_IMAGE="$(normalize_image "${LXD_IMAGE:-images:ubuntu/24.04}")"
log "Normalizing LXD_IMAGE: ${LXD_IMAGE:-unset} -> ${FIXED_IMAGE}"

# Patch .env safely, preserving other config.
if grep -q '^LXD_IMAGE=' "$ENV_FILE"; then
  sed -i.bak -E "s|^LXD_IMAGE=.*|LXD_IMAGE=\"${FIXED_IMAGE}\"|" "$ENV_FILE"
else
  printf '\nLXD_IMAGE="%s"\n' "$FIXED_IMAGE" >> "$ENV_FILE"
fi

# Patch all scripts that may have old literal image values.
log "Patching scripts to avoid ubuntu:24.04 fingerprint lookup"
find scripts -type f -name '*.sh' -print0 | while IFS= read -r -d '' f; do
  sed -i \
    -e 's|ubuntu:24\.04|images:ubuntu/24.04|g' \
    -e 's|ubuntu:noble|images:ubuntu/24.04|g' \
    -e 's|images:ubuntu:24\.04|images:ubuntu/24.04|g' \
    "$f"
done

log "Checking image alias availability"
if ! timeout 60 lxc image info "$FIXED_IMAGE" >/tmp/lxd-image-info.$$ 2>/tmp/lxd-image-err.$$; then
  err "Cannot resolve LXD image: $FIXED_IMAGE"
  cat /tmp/lxd-image-err.$$ >&2 || true
  warn "Available remotes:"
  lxc remote list || true
  warn "Try: lxc image list images: ubuntu/24.04 --format table | head -20"
  rm -f /tmp/lxd-image-info.$$ /tmp/lxd-image-err.$$
  exit 3
fi
rm -f /tmp/lxd-image-info.$$ /tmp/lxd-image-err.$$

log "Re-running Graph RAG creation with fixed image"
exec bash scripts/20_create_graph_rag.sh
