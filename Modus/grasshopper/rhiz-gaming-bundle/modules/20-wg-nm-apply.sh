#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd nmcli
need_cmd python3

if command -v systemctl >/dev/null 2>&1; then
  systemctl is-active --quiet NetworkManager || systemctl start NetworkManager || true
fi

yaml="${REPO_ROOT}/${WG_CEPH_DIRECTIVE_FILE:-directives/wg-ceph-operator.yaml}"
[[ -f "$yaml" ]] || die "Missing directives file: $yaml"
keyfile_path="/etc/NetworkManager/system-connections/${WG_CEPH_IF}.nmconnection"
sysconn_dir="$(dirname "${keyfile_path}")"
install -d -m 700 -o root -g root "${sysconn_dir}"
command -v restorecon >/dev/null 2>&1 && restorecon -RF "${sysconn_dir}" >/dev/null 2>&1 || true

log "Rendering NetworkManager WireGuard keyfile: ${keyfile_path}"

tmp_out="$(mktemp -p /tmp "${WG_CEPH_IF}.nmconnection.XXXXXX")"
python3 - "$yaml" "${WG_CEPH_IF}" "${WG_CEPH_PRIVATE_KEY_FILE}" <<'PY' > "${tmp_out}"
import sys, uuid, ipaddress
try:
    import yaml
except Exception as e:
    raise SystemExit("Missing PyYAML. Install python3-pyyaml / python3-yaml") from e

yaml_path, ifname, privkey_file = sys.argv[1:4]
with open(yaml_path, 'r', encoding='utf-8') as f:
    cfg = yaml.safe_load(f) or {}

iface = cfg.get("interface", {})
peers = cfg.get("peers", [])
listen_port = int(iface.get("listen_port", 51820))
mtu = int(iface.get("mtu", 1420))
address = str(iface.get("address", "")).strip()
never_default = bool(iface.get("never_default", True))
if not address:
    raise SystemExit("interface.address missing in directives file")

iface_ip = str(ipaddress.ip_interface(address).ip)
with open(privkey_file, "r", encoding="utf-8") as f:
    private_key = f.read().strip()
if not private_key:
    raise SystemExit("Private key file is empty.")

u = uuid.uuid5(uuid.NAMESPACE_DNS, f"exosys-wg-{ifname}-{address}")
lines = []
lines += ["[connection]", f"id={ifname}", f"uuid={u}", "type=wireguard", f"interface-name={ifname}", "autoconnect=true", ""]
lines += ["[wireguard]", f"listen-port={listen_port}", f"mtu={mtu}", f"private-key={private_key}", ""]
lines += ["[ipv4]", f"address1={address}", "method=manual", "ignore-auto-dns=true", "dns-search=~;", f"never-default={'true' if never_default else 'false'}", ""]
lines += ["[ipv6]", "method=disabled", ""]

for p in peers:
    name = (p.get("name") or "peer").strip()
    pub = (p.get("public_key") or "").strip()
    endpoint = (p.get("endpoint") or "").strip()
    allowed = p.get("allowed_ips") or ""
    keepalive = p.get("persistent_keepalive", 25)

    if isinstance(allowed, list):
        allowed_s = ",".join(str(x).strip() for x in allowed if str(x).strip())
    else:
        allowed_s = str(allowed).strip()

    # Skip placeholders and accidental self-peers.
    if not pub or pub.startswith("REPLACE_") or not allowed_s:
        continue

    allowed_items = [x.strip() for x in allowed_s.split(",") if x.strip()]
    peer_ips = []
    for item in allowed_items:
        try:
            peer_ips.append(str(ipaddress.ip_network(item, strict=False).network_address))
        except Exception:
            pass
    if iface_ip in peer_ips:
        continue

    lines += [f"[wireguard-peer.{name}]", f"public-key={pub}"]
    if endpoint and "REPLACE" not in endpoint:
        lines += [f"endpoint={endpoint}"]
    lines += [f"allowed-ips={allowed_s}"]
    if keepalive:
        lines += [f"persistent-keepalive={int(keepalive)}"]
    lines += [""]

sys.stdout.write("\n".join(lines).strip() + "\n")
PY

install -m 600 -o root -g root "${tmp_out}" "${keyfile_path}"
rm -f "${tmp_out}"

nmcli connection reload
nmcli connection up "${WG_CEPH_IF}" || true
log "Done."
