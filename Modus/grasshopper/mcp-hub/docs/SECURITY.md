# Security

## Defaults

- Plan-only by default.
- No network listener for MCP; stdio only.
- No LXD cluster DB mutation tools.
- No Bitcoin wallet/signing/broadcast RPC.
- No hidden deploy execution from MCP tools.

## Bitcoin denied RPC classes

Denied by `mcp-hub/src/hub.mjs` and `tools/bitcoin_allowlist.sh`:

- wallet loading/unloading
- private key export/import
- PSBT signing/funding
- transaction broadcast
- wallet balance/UTXO inspection

## LXD/Ceph

For direct LXD/Ceph probing, host-level systemd/client invocation is preferred over mounting privileged sockets into containers. If you choose the LXD container route, avoid exposing `/var/snap/lxd/common/lxd/unix.socket` unless the container is fully trusted.
