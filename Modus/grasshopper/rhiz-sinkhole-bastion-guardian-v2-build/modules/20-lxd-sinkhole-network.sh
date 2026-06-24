#!/usr/bin/env bash
set -euo pipefail
NET=${SINKHOLE_LXD_NETWORK:-sinkhole0}; GW=${SINKHOLE_GATEWAY:-10.45.3.1}
lxc network show "$NET" || lxc network create "$NET" ipv4.address="$GW/24" ipv4.nat=true ipv6.address=none
