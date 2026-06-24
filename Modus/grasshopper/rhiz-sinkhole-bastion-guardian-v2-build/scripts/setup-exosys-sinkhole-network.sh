#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && source .env && set +a
MODE="dry-run"; [[ "${1:-}" == "--apply" ]] && MODE="apply"; [[ "${1:-}" == "--dry-run" ]] && MODE="dry-run"
TARGET_HOSTNAME=${TARGET_HOSTNAME:-exosys-rhiz}; TARGET_HOST_IP=${TARGET_HOST_IP:-192.168.0.50}
NET=${SINKHOLE_LXD_NETWORK:-sinkhole0}; BR=${SINKHOLE_BRIDGE:-rhiz-sink0}; GW=${SINKHOLE_GATEWAY:-10.45.3.1}; DHCP=${SINKHOLE_DHCP_RANGE:-10.45.3.100-10.45.3.220}; DNS=${SINKHOLE_DNS_IP:-10.45.3.53}
echo "[sinkhole-net] mode=$MODE target=$TARGET_HOSTNAME/$TARGET_HOST_IP network=$NET bridge=$BR"
if [[ "$(hostname)" != "$TARGET_HOSTNAME" ]]; then echo "[warn] current host is $(hostname), expected $TARGET_HOSTNAME. Use SSH or remote-apply."; fi
CMDS=(
"lxc network show $NET >/dev/null 2>&1 || lxc network create $NET ipv4.address=$GW/24 ipv4.nat=true ipv6.address=none bridge.driver=native dns.mode=managed"
"lxc network set $NET bridge.external_interfaces ''"
"lxc network set $NET dns.domain sinkhole.rhiz.local"
"lxc network set $NET raw.dnsmasq 'dhcp-option=6,$DNS'"
"lxc network show $NET"
)
for c in "${CMDS[@]}"; do echo "+ $c"; [[ "$MODE" == "apply" ]] && bash -lc "$c"; done
cat <<EOF
Next: launch DNS sensor container attached to $NET and assign/static-route $DNS if desired.
EOF
