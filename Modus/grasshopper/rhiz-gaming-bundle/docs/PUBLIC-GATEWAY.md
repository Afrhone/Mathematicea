# Public endpoint gateway model

The public gateway host is used for:

- remote SSH / ProxyJump into the private Ceph/VPN subnet
- optional forwarded TCP ports to internal services such as the Ceph dashboard or libvirt TLS
- NAT/masquerade when a remote operator needs reachability into the VPN-managed control plane

The bundle uses `directives/public-gateway.yaml` as the source of truth and renders a generated SSH config from inventory.
