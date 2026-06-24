#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
OUT="$ROOT/config/${DIRECT_LINK_NAME}.nmconnection"
UUID="$(python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
)"
cat > "$OUT" <<EOF
[connection]
id=${DIRECT_LINK_NAME}
uuid=${UUID}
type=ethernet
interface-name=${PRIMARY_INTERFACE}
autoconnect=true

[ethernet]

[ipv4]
method=manual
addresses=${DIRECT_LINK_CIDR}
dns=${DIRECT_LINK_DNS}
never-default=true

[ipv6]
method=disabled
EOF
chmod 600 "$OUT"
cat "$OUT"
