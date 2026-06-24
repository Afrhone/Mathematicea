#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh
need_cmd base64

keyring="/etc/ceph/${CEPH_CLUSTER_NAME}.${CEPH_CLIENT}.keyring"
[[ -f "$keyring" ]] || die "Missing keyring: $keyring (run ceph-pool-auth)"

key="$(awk '/key =/ {print $3}' "$keyring" | head -n1)"
[[ -n "${key:-}" ]] || die "Could not extract key from keyring."

tmpl="${REPO_ROOT}/templates/libvirt/ceph-secret.xml"
tmp="/tmp/ceph-secret.xml"
sed -e "s|__UUID__|${LIBVIRT_CEPH_SECRET_UUID}|g" -e "s|__USAGE_NAME__|${LIBVIRT_CEPH_SECRET_NAME}|g" "$tmpl" > "$tmp"

if ! virsh secret-list | awk '{print $1}' | grep -q "${LIBVIRT_CEPH_SECRET_UUID}"; then
  virsh secret-define --file "$tmp"
fi

b64="$(printf "%s" "$key" | base64 -w0)"
virsh secret-set-value --secret "${LIBVIRT_CEPH_SECRET_UUID}" --base64 "$b64"
log "Libvirt secret ready."
