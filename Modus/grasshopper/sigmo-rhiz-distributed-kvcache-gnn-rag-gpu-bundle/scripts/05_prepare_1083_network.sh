#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

PROFILE="rhiz-kv83"

log "Creating/updating LXD profile $PROFILE for ${KV_NET_CIDR}"
if ! lxc profile show "$PROFILE" >/dev/null 2>&1; then
  lxc profile create "$PROFILE"
fi

cat > /tmp/${PROFILE}.yaml <<EOF
config: {}
description: RHIZ second-interface state/KV network profile
devices:
  eth1:
    name: eth1
    nictype: ${KV_NET_NICTYPE}
    parent: ${KV_NET_PARENT}
    type: nic
name: ${PROFILE}
used_by: []
EOF

lxc profile edit "$PROFILE" < /tmp/${PROFILE}.yaml
rm -f /tmp/${PROFILE}.yaml

log "Profile ready: $PROFILE"
lxc profile show "$PROFILE"
