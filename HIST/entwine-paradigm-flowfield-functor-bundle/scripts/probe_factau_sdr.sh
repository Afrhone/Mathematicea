#!/usr/bin/env bash
set -Eeuo pipefail
curl -s --max-time 5 http://192.168.0.4:8099/health || true
echo
curl -s --max-time 5 http://192.168.0.4:8099/spectrum | head -c 1000 || true
echo
echo "SSH: ssh kobalt@192.168.0.4"
