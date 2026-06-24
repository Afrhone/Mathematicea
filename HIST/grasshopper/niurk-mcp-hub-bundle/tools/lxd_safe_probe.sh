#!/usr/bin/env bash
set -euo pipefail
project="${1:-${NIURK_PROJECT:-default}}"
lxc cluster list || true
lxc storage list || true
lxc network list || true
lxc list --project "$project" || true
