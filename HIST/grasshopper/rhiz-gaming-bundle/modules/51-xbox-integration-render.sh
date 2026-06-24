#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

vm="${1:-${WIN_GUEST_NAME:-valkyrie-win11}}"
out="$(generated_dir)/windows-gaming/${vm}/xbox-one-integration.md"
mkdir -p "$(dirname -- "$out")"

cat > "$out" <<EOX
# Xbox One integration for ${vm}

## Practical paths

### A. Xbox One as Moonlight client for the Windows gaming VM

1. Install Moonlight on the Xbox One.
2. Ensure Sunshine is installed in the Windows VM.
3. Pair the Xbox client to the Sunshine host.
4. Add Desktop, Steam Big Picture, and/or Playnite Fullscreen in Sunshine.
5. Prefer Ethernet from Xbox -> LAN -> Fedora host fabric for lowest latency.

### B. Xbox One as official Xbox Cloud Gaming endpoint

Use this for Xbox catalog cloud titles. This is separate from your self-hosted VM.

### C. Xbox One as physical-console Remote Play source

Keep this separate from the Windows VM lane.

## Local network suggestions

- Keep Sunshine limited to private CIDRs.
- Put the gaming host and Xbox One on the lowest-latency LAN path available.
- If you already run WireGuard overlay addressing, keep the Sunshine host reachable on the overlay but prioritize local-LAN pairing first.

## What not to do

- Do not attempt to use the Xbox One as a Ceph node.
- Do not attempt to use the Xbox One as a libvirt worker.
- Do not expect the Xbox One GPU to become part of the shared GPU pool.
EOX

log "Rendered Xbox integration notes: $out"
