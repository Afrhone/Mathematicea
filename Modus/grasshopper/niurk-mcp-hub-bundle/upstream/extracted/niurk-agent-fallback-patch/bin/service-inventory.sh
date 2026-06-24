#!/usr/bin/env bash
set -euo pipefail
NIURK_ROOT="${NIURK_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$NIURK_ROOT/bin/lib/niurk-lib.sh"

target="${1:-all}"
out="$NIURK_STATE_DIR/inventory-$TS"
mkdir -p "$out"

SSH_USER="${SSH_USER:-kobalt}"
SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-8}"
SSH_BATCH_MODE="${SSH_BATCH_MODE:-no}"
SSH_STRICT_HOST_KEY_CHECKING="${SSH_STRICT_HOST_KEY_CHECKING:-accept-new}"

safe_name() { printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'; }

instance_ip_from_env() {
  local inst="$1"
  case "$inst" in
    "${SOURCE_VM:-}") printf '%s' "${SOURCE_VM_IP:-}" ;;
    "${TARGET_VM:-}") printf '%s' "${TARGET_VM_IP:-}" ;;
    "${LEGACY_VM:-}") printf '%s' "${LEGACY_VM_IP:-}" ;;
    "${LLAMA_GPU_CONTAINER:-}") printf '%s' "${LLAMA_GPU_IP:-}" ;;
    "${AI_CONTAINER:-}") printf '%s' "${AI_CONTAINER_IP:-}" ;;
    *) printf '' ;;
  esac
}

instance_ip_from_lxc_list() {
  local inst="$1"
  lxc list "$inst" -c 4 --format csv 2>/dev/null \
    | tr ' ,' '\n\n' \
    | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    | grep -Ev '^(127\.|169\.254\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|10\.)' \
    | head -1 || true
}

resolve_instance_ip() {
  local inst="$1" ip
  ip="$(instance_ip_from_env "$inst")"
  if [[ -z "$ip" ]]; then
    ip="$(instance_ip_from_lxc_list "$inst")"
  fi
  printf '%s' "$ip"
}

write_guest_script() {
  cat <<'REMOTE_SCRIPT'
set +e
section() { printf '\n===== %s =====\n' "$*"; }
cmd() { printf '\n$ %s\n' "$*"; bash -lc "$*" 2>&1 || true; }
section "identity"
cmd 'date -Is'
cmd 'hostnamectl || hostname -f || hostname'
cmd 'id || true'
cmd 'cat /etc/os-release || true'
cmd 'uname -a'
section "network"
cmd 'ip -br a || true'
cmd 'ip route || true'
cmd 'ss -lntup || true'
section "memory-disk-pressure"
cmd 'uptime || true'
cmd 'free -h || true'
cmd 'swapon --show || true'
cmd 'df -hT || true'
cmd 'lsblk -f || true'
cmd 'vmstat 1 3 || true'
cmd 'iostat -xz 1 3 || true'
section "services"
cmd 'systemctl --failed --no-pager || true'
cmd 'systemctl list-units --type=service --state=running --no-pager || true'
cmd 'systemctl list-unit-files --type=service --state=enabled --no-pager || true'
section "docker"
cmd 'docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" || true'
cmd 'docker compose ls || true'
cmd 'docker network ls || true'
section "compose-files"
if [[ -n "${PROJECT_ROOTS:-}" ]]; then
  # shellcheck disable=SC2086
  find ${PROJECT_ROOTS} -maxdepth 6 \( -name compose.yaml -o -name compose.yml -o -name docker-compose.yml -o -name docker-compose.yaml \) -print 2>/dev/null || true
fi
section "top-processes"
cmd 'ps -eo pid,user,pcpu,pmem,stat,lstart,args --sort=-%mem | head -120 || true'
section "recent-kernel-journal"
cmd 'dmesg -T | tail -160 || true'
cmd 'journalctl -p warning..alert -n 160 --no-pager || true'
REMOTE_SCRIPT
}

write_host_side_inventory() {
  local inst="$1" dir="$2"
  {
    echo "# host-side LXD inventory for $inst"
    echo "# time: $(date -Is)"
    echo
    echo "## lxc list"
    lxc list "$inst" -c ns4tL || true
    echo
    echo "## lxc info"
    lxc info "$inst" || true
    echo
    echo "## lxc config show --expanded"
    lxc config show "$inst" --expanded || true
    echo
    echo "## lxc config device show"
    lxc config device show "$inst" || true
    echo
    echo "## location/state"
    printf 'state=%s\n' "$(instance_state "$inst" 2>/dev/null || true)"
    printf 'location=%s\n' "$(instance_location "$inst" 2>/dev/null || true)"
  } > "$dir/host-lxd.txt" 2>&1
}

inventory_via_lxc_exec() {
  local inst="$1" dir="$2" script
  script="$(mktemp)"
  write_guest_script > "$script"
  lxc exec "$inst" -- env PROJECT_ROOTS="$PROJECT_ROOTS" bash -s < "$script" > "$dir/guest-via-lxd-agent.txt" 2>&1
  local rc=$?
  rm -f "$script"
  return "$rc"
}

inventory_via_ssh() {
  local inst="$1" ip="$2" user="$3" dir="$4" script
  [[ -n "$ip" ]] || return 22
  script="$(mktemp)"
  write_guest_script > "$script"
  ssh \
    -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" \
    -o BatchMode="$SSH_BATCH_MODE" \
    -o StrictHostKeyChecking="$SSH_STRICT_HOST_KEY_CHECKING" \
    "$user@$ip" \
    "PROJECT_ROOTS=$(printf '%q' "$PROJECT_ROOTS") bash -s" \
    < "$script" > "$dir/guest-via-ssh.txt" 2>&1
  local rc=$?
  rm -f "$script"
  return "$rc"
}

inventory_instance() {
  local inst="$1" ip dir ssh_user state
  [[ -n "$inst" ]] || return 0
  dir="$out/$inst"
  mkdir -p "$dir"
  log "inventory $inst -> $dir"

  write_host_side_inventory "$inst" "$dir"

  state="$(instance_state "$inst" 2>/dev/null || true)"
  if [[ "$state" != "RUNNING" ]]; then
    warn "$inst is not running (host-side metadata only)"
    return 0
  fi

  if inventory_via_lxc_exec "$inst" "$dir"; then
    ok "$inst guest inventory via lxd-agent"
    printf '{"instance":"%s","method":"lxd-agent","time":"%s"}\n' "$inst" "$(date -Is)" > "$dir/method.json"
    return 0
  fi

  warn "$inst lxd-agent inventory failed; trying SSH fallback"
  ip="$(resolve_instance_ip "$inst")"
  ssh_user="${NIURK_SSH_USER:-$SSH_USER}"
  if [[ -z "$ip" ]]; then
    warn "$inst has no resolvable SSH IP; host-side metadata only"
    printf '{"instance":"%s","method":"host-only","reason":"no-ip","time":"%s"}\n' "$inst" "$(date -Is)" > "$dir/method.json"
    return 0
  fi

  if inventory_via_ssh "$inst" "$ip" "$ssh_user" "$dir"; then
    ok "$inst guest inventory via SSH $ssh_user@$ip"
    printf '{"instance":"%s","method":"ssh","ip":"%s","user":"%s","time":"%s"}\n' "$inst" "$ip" "$ssh_user" "$(date -Is)" > "$dir/method.json"
    return 0
  fi

  warn "$inst SSH fallback failed for $ssh_user@$ip; host-side metadata only"
  printf '{"instance":"%s","method":"host-only","reason":"ssh-failed","ip":"%s","user":"%s","time":"%s"}\n' "$inst" "$ip" "$ssh_user" "$(date -Is)" > "$dir/method.json"
}

case "$target" in
  source) inventory_instance "${SOURCE_VM:-}" ;;
  target) inventory_instance "${TARGET_VM:-}" ;;
  legacy) inventory_instance "${LEGACY_VM:-}" ;;
  ai) inventory_instance "${AI_CONTAINER:-}" ;;
  all)
    inventory_instance "${SOURCE_VM:-}"
    inventory_instance "${TARGET_VM:-}"
    if [[ -n "${AI_CONTAINER:-}" && "$(instance_state "$AI_CONTAINER" 2>/dev/null || true)" == "RUNNING" ]]; then
      inventory_instance "$AI_CONTAINER"
    fi
    ;;
  *) die "usage: $0 [source|target|legacy|ai|all]" ;;
esac

ok "inventory path: $out"
