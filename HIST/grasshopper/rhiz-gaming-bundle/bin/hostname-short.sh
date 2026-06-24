#!/usr/bin/env bash
set -euo pipefail
# Optional: convert FQDN hostname (host.domain) -> short hostname (host) for cephadm friendliness.
# Usage: sudo ./bin/hostname-short.sh factau-rhiz
# This updates hostname via hostnamectl and ensures /etc/hosts has a mapping.

new="${1:-}"
if [[ -z "$new" ]]; then
  echo "Usage: $0 <short-hostname>" >&2
  exit 1
fi

old="$(hostname)"
echo "Old hostname: ${old}"
echo "New hostname: ${new}"

hostnamectl set-hostname "${new}"

# Ensure /etc/hosts has 127.0.1.1 mapping
if ! grep -qE '^127\.0\.1\.1\s+' /etc/hosts; then
  echo "127.0.1.1 ${new}" >> /etc/hosts
else
  # replace existing 127.0.1.1 line
  tmp="$(mktemp)"
  awk -v h="${new}" '
    BEGIN{done=0}
    /^127\.0\.1\.1\s+/{print "127.0.1.1 " h; done=1; next}
    {print}
    END{if(!done) print "127.0.1.1 " h}
  ' /etc/hosts > "$tmp"
  mv "$tmp" /etc/hosts
fi

echo "Now: $(hostname)"
