#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
lxc exec "$RHIZ_LAB_NAME" -- bash -lc 'curl -fsS http://127.0.0.1:8091/health | jq . || true; curl -fsS http://127.0.0.1:8092/health | jq . || true; curl -fsS http://127.0.0.1:8093/health | jq . || true; curl -fsS http://127.0.0.1:8094 >/dev/null || true'
