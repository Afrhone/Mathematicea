#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd python3
need_cmd firewall-cmd
cfg="$(gateway_json "$(gateway_file)")"
[[ "$cfg" != "{}" ]] || die "Missing gateway config"
readarray -t vals < <(python3 - "$cfg" <<'PY'
import json, sys
c=json.loads(sys.argv[1])
print(c.get('host',''))
print(c.get('public_iface',''))
print(c.get('vpn_iface','ceph-operator'))
print(str(c.get('configure_ip_forward', True)).lower())
print(str(c.get('enable_masquerade', True)).lower())
for s in c.get('open_services', []):
    print('SERVICE:'+str(s))
for p in c.get('open_udp_ports', []):
    print('UDP:'+str(p))
for f in c.get('forwards', []):
    print('FWD:%s:%s:%s:%s' % (f.get('proto','tcp'), f.get('listen_port',''), f.get('target_addr',''), f.get('target_port','')))
PY
)
gw_host="${vals[0]}"; public_if="${vals[1]}"; vpn_if="${vals[2]}"; do_fwd="${vals[3]}"; do_masq="${vals[4]}"
[[ "$(hostname -s)" == "$gw_host" ]] || warn "Current host $(hostname -s) is not gateway host ${gw_host}; applying anyway"
if is_yes "$do_fwd"; then printf 'net.ipv4.ip_forward = 1\n' >/etc/sysctl.d/99-exosys-gateway.conf; sysctl --system >/dev/null || true; fi
firewall-cmd --permanent --zone "${GATEWAY_PUBLIC_ZONE:-public}" --add-interface "$public_if" || true
firewall-cmd --permanent --zone "${GATEWAY_VPN_ZONE:-trusted}" --add-interface "$vpn_if" || true
for item in "${vals[@]:5}"; do
  case "$item" in
    SERVICE:*) firewall-cmd --permanent --zone "${GATEWAY_PUBLIC_ZONE:-public}" --add-service "${item#SERVICE:}" || true ;;
    UDP:*) firewall-cmd --permanent --zone "${GATEWAY_PUBLIC_ZONE:-public}" --add-port "${item#UDP:}/udp" || true ;;
    FWD:*)
      IFS=':' read -r _ proto listen target_addr target_port <<<"$item"
      firewall-cmd --permanent --zone "${GATEWAY_PUBLIC_ZONE:-public}" --add-forward-port="port=${listen}:proto=${proto}:toaddr=${target_addr}:toport=${target_port}" || true
      ;;
  esac
done
if is_yes "$do_masq"; then firewall-cmd --permanent --zone "${GATEWAY_PUBLIC_ZONE:-public}" --add-masquerade || true; fi
firewall-cmd --reload || true
mkdir -p "$(generated_dir)"
sed "s|\${PUBLIC_ENDPOINT}|${PUBLIC_ENDPOINT:-rhiz-arch.afrho.net}|g" "${REPO_ROOT}/templates/gateway/Caddyfile.template" > "$(generated_dir)/Caddyfile"
log "Gateway rules applied and generated/Caddyfile rendered."
