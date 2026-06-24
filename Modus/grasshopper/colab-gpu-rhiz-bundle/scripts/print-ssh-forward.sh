#!/usr/bin/env bash
set -euo pipefail
VM_IP="${1:?VM IP missing}"
PORT="${2:-9000}"
echo "ssh -L ${PORT}:127.0.0.1:${PORT} ubuntu@${VM_IP}"
