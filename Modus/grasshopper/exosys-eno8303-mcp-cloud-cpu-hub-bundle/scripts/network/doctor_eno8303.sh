#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
echo "=== eno8303 doctor ==="
hostname
ip -br link show "$PRIMARY_INTERFACE" || true
ip -br addr show "$PRIMARY_INTERFACE" || true
nmcli device status || true
nmcli connection show || true
ethtool "$PRIMARY_INTERFACE" || true
ip route
ss -lntup | grep -E ':7190|:7191|:7192|:7193|:7194|:7195' || true
