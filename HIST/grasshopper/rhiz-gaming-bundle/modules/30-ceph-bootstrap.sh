#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd cephadm
need_cmd ip

log "Ceph bootstrap preflight..."
if ! ip -4 addr show | grep -q " ${CEPH_BOOTSTRAP_MON_IP}/"; then
  warn "The IP ${CEPH_BOOTSTRAP_MON_IP} is NOT assigned on this host."
  die "Fix .env or assign the IP before bootstrapping."
fi

if [[ -f "/etc/ceph/${CEPH_CLUSTER_NAME}.conf" ]]; then
  warn "Ceph already bootstrapped (found /etc/ceph/${CEPH_CLUSTER_NAME}.conf)."
  exit 0
fi

allow_mode="${CEPH_ALLOW_FQDN_HOSTNAME:-auto}"
allow_flag=""
hn="$(hostname)"
if [[ "$allow_mode" == "yes" ]]; then
  allow_flag="--allow-fqdn-hostname"
elif [[ "$allow_mode" == "auto" && "$hn" == *.* ]]; then
  allow_flag="--allow-fqdn-hostname"
fi

skip_monitoring="${CEPH_SKIP_MONITORING_STACK:-yes}"
skip_monitoring_flag=""
if is_yes "$skip_monitoring"; then
  skip_monitoring_flag="--skip-monitoring-stack"
fi

dashboard_flags=()
if [[ -n "${CEPH_DASHBOARD_USER:-}" ]]; then
  dashboard_flags+=(--initial-dashboard-user "${CEPH_DASHBOARD_USER}")
fi
if [[ -n "${CEPH_DASHBOARD_PASSWORD:-}" ]]; then
  dashboard_flags+=(--initial-dashboard-password "${CEPH_DASHBOARD_PASSWORD}")
fi

release_args=()
if [[ -n "${CEPH_IMAGE:-}" ]]; then
  release_args+=(--image "${CEPH_IMAGE}")
fi

cephadm bootstrap \
  --mon-ip "${CEPH_BOOTSTRAP_MON_IP}" \
  --cluster-network "${CEPH_CLUSTER_NETWORK}" \
  --ssh-user "${CEPH_SSH_USER:-root}" \
  ${allow_flag} \
  ${skip_monitoring_flag} \
  "${dashboard_flags[@]}" \
  "${release_args[@]}"

log "Bootstrap complete."
