#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
d="${REPO_ROOT}/directives"
mkdir -p "${d}/swarm"

cat > "${d}/hosts.yaml" <<EOF
hosts:
  - name: ${HOSTNAME_OVERRIDE:-$(hostname -s)}
    role: fedora-host
    public_if: ${HOST_PUBLIC_IF}
    wireguard:
      iface: ${HOST_WG_IF}
      address: ${HOST_WG_IP}
      listen_port: ${HOST_WG_PORT}
    libvirt:
      network: ${LIBVIRT_NETWORK_NAME}
      bridge: ${LIBVIRT_BRIDGE_NAME}
  - name: ${VM_NAME}
    role: ubuntu-colab-vm
    guest_user: ${VM_GUEST_USER}
    wireguard:
      address: ${VM_WG_IP}
    lxd:
      bridge: ${VM_LXD_BRIDGE}
      storage_pool: ${VM_LXD_STORAGE_POOL}
EOF

cat > "${d}/wireguard.yaml" <<EOF
wireguard:
  iface: ${HOST_WG_IF}
  subnet: ${WG_SUBNET}
  listen_port: ${HOST_WG_PORT}
  host:
    address: ${HOST_WG_IP}
  vm:
    address: ${VM_WG_IP}
  routed_subnets:
    - ${VM_LXD_BRIDGE_CIDR}
EOF

cat > "${d}/ceph.yaml" <<EOF
ceph:
  enabled: ${CEPH_ENABLE}
  cluster_name: ${CEPH_CLUSTER_NAME}
  client_name: ${CEPH_CLIENT_NAME}
  mon_hosts: [$(echo "${CEPH_MON_HOSTS}" | sed 's/,/", "/g; s/^/"/; s/$/"/')]
  cephfs:
    enabled: ${CEPHFS_ENABLE}
    fs_name: ${CEPHFS_NAME}
    mount: ${CEPHFS_MOUNT}
    subpath: ${CEPHFS_SUBPATH}
EOF

cat > "${d}/lxd-profile.yaml" <<EOF
lxd:
  bridge: ${VM_LXD_BRIDGE}
  bridge_cidr: ${VM_LXD_BRIDGE_CIDR}
  storage_pool: ${VM_LXD_STORAGE_POOL}
  profile: ${VM_LXD_CPU_PROFILE}
  limits:
    cpu: "${VM_LXD_CPU_LIMIT}"
    memory: "${VM_LXD_MEMORY_LIMIT}"
  sample_containers: [$(echo "${VM_LXD_SAMPLE_CONTAINERS}" | sed 's/,/", "/g; s/^/"/; s/$/"/')]
EOF

cat > "${d}/swarm/vllm-stack.yaml" <<'EOF'
version: "3.9"
services:
  vllm:
    image: vllm/vllm-openai:latest
    command:
      - --model
      - meta-llama/Llama-3.2-1B-Instruct
      - --host
      - 0.0.0.0
      - --port
      - "8000"
    environment:
      - HUGGING_FACE_HUB_TOKEN=${HUGGING_FACE_HUB_TOKEN:-}
    ports:
      - target: 8000
        published: 8000
        protocol: tcp
        mode: ingress
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    networks:
      - inference-net
    volumes:
      - /srv/cephfs/models:/models
networks:
  inference-net:
    external: true
EOF

log "Rendered directives under ${d}"
