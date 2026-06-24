#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

assert_package

mkdir -p "$ROOT/logs"
SUMMARY="$ROOT/logs/push-summary-$(date +%Y%m%d-%H%M%S).ndjson"
log "Writing summary to $SUMMARY"

while IFS= read -r row; do
  name="$(host_name "$row")"
  ssh_host="$(host_ssh "$row")"
  ip="$(host_ip "$row")"
  roles="$(host_roles "$row")"

  log "=== $name ssh_host=$ssh_host ip=$ip roles=$roles ==="

  set +e
  "$ROOT/scripts/push_one_host.sh" "$ssh_host"
  rc=$?
  if [[ "$rc" -ne 0 && "$ssh_host" != "$ip" ]]; then
    log "Primary host failed for $name; trying IP fallback $ip"
    "$ROOT/scripts/push_one_host.sh" "$ip"
    rc=$?
  fi
  set -e

  printf '{"time":"%s","host":"%s","ssh_host":"%s","ip":"%s","rc":%s}\n' \
    "$(date -Is)" "$name" "$ssh_host" "$ip" "$rc" >> "$SUMMARY"

  [[ "$rc" -eq 0 ]] || die "push failed for $name"
done < <(host_rows)

log "All hosts pushed"
cat "$SUMMARY"
