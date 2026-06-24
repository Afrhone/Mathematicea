#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && source .env && set +a
mkdir -p runtime
cat > runtime/sinkhole-network.plan <<EOF
Target: ${TARGET_HOSTNAME:-exosys-rhiz} ${TARGET_HOST_IP:-192.168.0.50}
LXD network: ${SINKHOLE_LXD_NETWORK:-sinkhole0}
Bridge: ${SINKHOLE_BRIDGE:-rhiz-sink0}
Subnet: ${SINKHOLE_SUBNET:-10.45.3.0/24}
Gateway: ${SINKHOLE_GATEWAY:-10.45.3.1}
DNS: ${SINKHOLE_DNS_IP:-10.45.3.53}
EOF
cat runtime/sinkhole-network.plan
