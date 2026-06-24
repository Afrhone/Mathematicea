#!/usr/bin/env bash
set -euo pipefail

# Optional helper: prepare a NetworkManager keyfile on factau-rhiz.
# Preferred approach remains: sudo ./bin/exosys.sh wg-apply

KEYFILE="/etc/NetworkManager/system-connections/ceph-operator.nmconnection"
TEMPLATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../configs/factau-rhiz/NetworkManager" && pwd)"
TEMPLATE="${TEMPLATE_DIR}/ceph-operator.nmconnection.template"

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "Missing template: ${TEMPLATE}" >&2
  exit 1
fi

UUID="$(python3 - <<'PY'
import uuid
print(uuid.uuid5(uuid.NAMESPACE_DNS, "exosys-wg-ceph-operator"))
PY
)"

tmp="$(mktemp)"
sed -e "s|__UUID__|${UUID}|g" "${TEMPLATE}" > "${tmp}"

echo "Prepared: ${tmp}"
echo
echo "Edit it to insert __PRIVATE_KEY__ + peer details, then install:"
echo "  sudo install -m 600 -o root -g root ${tmp} ${KEYFILE}"
echo "  sudo nmcli connection reload"
echo "  sudo nmcli connection up ceph-operator"
