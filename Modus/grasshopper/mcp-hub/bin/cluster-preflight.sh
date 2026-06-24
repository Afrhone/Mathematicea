#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
log "preflight root=$ROOT_DIR dry_run=${DRY_RUN:-${NIURK_DRY_RUN:-1}} allow_commands=${NIURK_ALLOW_COMMANDS:-0}"

printf '\n== runtime ==\n'
command -v node && node --version || true
command -v npm && npm --version || true

printf '\n== LXD ==\n'
command -v lxc && lxc --version || true
if [[ "${NIURK_ALLOW_COMMANDS:-0}" == "1" ]]; then
  lxc cluster list || true
  lxc storage list || true
  lxc network list || true
  lxc list --project "${NIURK_PROJECT:-default}" || true
else
  echo "skip live lxc probes: set NIURK_ALLOW_COMMANDS=1"
fi

printf '\n== Ceph ==\n'
ls -l "${NIURK_CEPH_CONF:-/etc/ceph/ceph.conf}" "${NIURK_CEPH_KEYRING:-/etc/ceph/ceph.client.admin.keyring}" 2>/dev/null || true
if [[ "${NIURK_ALLOW_COMMANDS:-0}" == "1" ]]; then
  ceph -s || true
  ceph fs status || true
  rbd --pool "${NIURK_RBD_POOL:-lxd-rbd-ark}" list || true
else
  echo "skip live ceph probes: set NIURK_ALLOW_COMMANDS=1"
fi

printf '\n== Bitcoin read-only ==\n'
if [[ "${ENABLE_BITCOIN:-0}" == "1" && "${NIURK_ALLOW_COMMANDS:-0}" == "1" ]]; then
  "${BITCOIN_CLI:-bitcoin-cli}" getblockchaininfo || true
  "${BITCOIN_CLI:-bitcoin-cli}" getmempoolinfo || true
else
  echo "skip bitcoin probes: set ENABLE_BITCOIN=1 and NIURK_ALLOW_COMMANDS=1"
fi

printf '\n== dashboard ==\n'
test -f "$ROOT_DIR/dashboard/infrasys-webgl/index.html" && echo "dashboard present" || echo "dashboard missing"
