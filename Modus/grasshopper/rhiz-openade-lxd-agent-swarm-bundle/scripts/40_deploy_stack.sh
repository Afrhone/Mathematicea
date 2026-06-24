#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
lxc exec "$RHIZ_LAB_NAME" -- bash -lc 'cd /opt/rhiz-openade-lab && docker compose -f docker/docker-compose.yml up -d --build && docker ps'
