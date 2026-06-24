#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
need_root
log "Configuring conservative memory guard for 8GB Pi"
run mkdir -p /etc/systemd/zram-generator.conf.d
cat >/tmp/freebeings-zram.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
EOF
run install -m 0644 /tmp/freebeings-zram.conf /etc/systemd/zram-generator.conf.d/freebeings.conf
if [ ! -f /swapfile ]; then
  run fallocate -l 4G /swapfile
  run chmod 600 /swapfile
  run mkswap /swapfile
fi
if ! grep -q '^/swapfile' /etc/fstab 2>/dev/null; then
  echo '/swapfile none swap sw 0 0' | if [ "$DRY_RUN" = "1" ]; then cat; else tee -a /etc/fstab >/dev/null; fi
fi
run sysctl vm.swappiness=30
log "Reboot recommended for zram-generator activation."
