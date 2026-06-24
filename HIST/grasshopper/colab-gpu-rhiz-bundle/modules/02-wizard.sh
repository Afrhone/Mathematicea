#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"

disc_env="${REPO_ROOT}/generated/discovery.env"
[[ -f "$disc_env" ]] && source "$disc_env" || true

host_if_default="${DISCOVERED_HOST_IF:-$(default_route_iface || true)}"
host_ip_default="${DISCOVERED_HOST_IP:-$(default_ipv4 || true)}"
host_name_default="${DISCOVERED_HOSTNAME:-$(hostname -s)}"
mem_default="${DISCOVERED_MEM_MB:-24576}"
vcpu_default="${DISCOVERED_VCPUS:-8}"
vm_ram_default="$(( mem_default > 32768 ? 24576 : mem_default / 2 ))"
[[ "$vm_ram_default" -lt 8192 ]] && vm_ram_default=8192
vm_vcpu_default="$(( vcpu_default > 8 ? 8 : (vcpu_default>2?vcpu_default-1:2) ))"

echo
echo "Colab GPU Rhiz wizard"
echo

HOSTNAME_OVERRIDE="$(prompt_default 'Fedora host short name' "$host_name_default")"
HOST_PUBLIC_IF="$(prompt_default 'Fedora public interface' "$host_if_default")"
VM_NAME="$(prompt_default 'VM name' 'colab-gpu')"
VM_GUEST_USER="$(prompt_default 'VM guest user' 'ubuntu')"
VM_VCPUS="$(prompt_default 'VM vCPUs' "$vm_vcpu_default")"
VM_RAM_MB="$(prompt_default 'VM RAM (MB)' "$vm_ram_default")"
VM_DISK_SIZE="$(prompt_default 'VM disk size' '160G')"
VM_SSH_PUBKEY_FILE="$(prompt_default 'SSH public key file for VM access' "${HOME}/.ssh/id_ed25519.pub")"
VM_GPU_PASSTHROUGH_PCI="$(prompt_default 'Comma-separated PCI GPU devices (blank for CPU-only)' '')"
HOST_WG_PORT="$(prompt_default 'Host WireGuard UDP port' '51890')"
HOST_WG_IP="$(prompt_default 'Host WireGuard address/CIDR' '10.44.60.1/24')"
VM_WG_IP="$(prompt_default 'VM WireGuard address/CIDR' '10.44.60.2/24')"
LIBVIRT_NETWORK_NAME="$(prompt_default 'libvirt network name' 'colab-vm-net')"
LIBVIRT_BRIDGE_NAME="$(prompt_default 'libvirt bridge name' 'virbr-colab')"
LIBVIRT_NETWORK_CIDR="$(prompt_default 'libvirt NAT CIDR' '192.168.233.0/24')"
LIBVIRT_GATEWAY="$(prompt_default 'libvirt gateway IP' '192.168.233.1')"
LIBVIRT_DHCP_START="$(prompt_default 'libvirt DHCP start' '192.168.233.100')"
LIBVIRT_DHCP_END="$(prompt_default 'libvirt DHCP end' '192.168.233.199')"
GOOGLE_CLOUD_ENABLE="$(prompt_default 'Enable Google Cloud CLI in VM (yes/no)' 'yes')"
GOOGLE_CLOUD_PROJECT="$(prompt_default 'Google Cloud project ID' '')"
GOOGLE_CLOUD_REGION="$(prompt_default 'Google Cloud region' 'europe-west6')"
CEPH_ENABLE="$(prompt_default 'Enable Ceph integration (yes/no)' 'yes')"
CEPH_MON_HOSTS="$(prompt_default 'Ceph monitor hosts (comma-separated)' '10.42.0.38,10.42.0.39,10.42.0.40')"
CEPH_CLIENT_NAME="$(prompt_default 'Ceph client name (without leading client.)' 'colab')"
VM_LXD_CPU_LIMIT="$(prompt_default 'LXD CPU profile limits.cpu' '4')"
VM_LXD_MEMORY_LIMIT="$(prompt_default 'LXD CPU profile memory limit' '8GiB')"

if [[ -n "$VM_GPU_PASSTHROUGH_PCI" ]]; then
  COLAB_USE_GPU=yes
  VM_GPU_ATTACH_AT_INSTALL=yes
else
  COLAB_USE_GPU=auto
  VM_GPU_ATTACH_AT_INSTALL=no
fi

cat > "${REPO_ROOT}/.env" <<EOF
GENERATED_DIR=generated
DISCOVERY_JSON=generated/discovery.json
DISCOVERY_ENV=generated/discovery.env
SSH_STRICT_HOSTKEY=accept-new
SSH_KEY_PATH=
VM_GUEST_USER=${VM_GUEST_USER}
VM_NAME=${VM_NAME}
VM_OS_VARIANT=ubuntu24.04
VM_MACHINE_TYPE=q35
VM_VCPUS=${VM_VCPUS}
VM_RAM_MB=${VM_RAM_MB}
VM_DISK_SIZE=${VM_DISK_SIZE}
VM_CPU_MODE=host-passthrough
VM_AUTO_START=yes
VM_CLOUD_IMAGE_URL=https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img
VM_SSH_PUBKEY_FILE=${VM_SSH_PUBKEY_FILE}
VM_STORAGE_DIR=/var/lib/libvirt/images/${VM_NAME}
VM_GPU_PASSTHROUGH_PCI=${VM_GPU_PASSTHROUGH_PCI}
VM_GPU_ATTACH_AT_INSTALL=${VM_GPU_ATTACH_AT_INSTALL}
HOSTNAME_OVERRIDE=${HOSTNAME_OVERRIDE}
HOST_PUBLIC_IF=${HOST_PUBLIC_IF}
HOST_PUBLIC_ZONE=public
HOST_LIBVIRT_ZONE=libvirt
HOST_WG_PORT=${HOST_WG_PORT}
HOST_WG_IF=wg-colab
HOST_WG_IP=${HOST_WG_IP}
VM_WG_IP=${VM_WG_IP}
WG_SUBNET=10.44.60.0/24
WG_CLUSTER_ALLOWED_IPS=10.44.60.0/24,10.210.0.0/24
WG_PERSISTENT_KEEPALIVE=25
LIBVIRT_NETWORK_NAME=${LIBVIRT_NETWORK_NAME}
LIBVIRT_BRIDGE_NAME=${LIBVIRT_BRIDGE_NAME}
LIBVIRT_NETWORK_CIDR=${LIBVIRT_NETWORK_CIDR}
LIBVIRT_GATEWAY=${LIBVIRT_GATEWAY}
LIBVIRT_DHCP_START=${LIBVIRT_DHCP_START}
LIBVIRT_DHCP_END=${LIBVIRT_DHCP_END}
LIBVIRT_DNS_DOMAIN=colab.internal
HOST_INSTALL_LXD=yes
HOST_LXD_CHANNEL=5.21/stable
HOST_LXD_BRIDGE=lxdbr-colab
HOST_LXD_BRIDGE_CIDR=10.211.0.1/24
HOST_LXD_STORAGE_POOL=default
VM_INSTALL_LXD=yes
VM_LXD_CHANNEL=5.21/stable
VM_LXD_BRIDGE=lxdbr0
VM_LXD_BRIDGE_CIDR=10.210.0.1/24
VM_LXD_STORAGE_POOL=default
VM_LXD_CPU_PROFILE=cpu-colab
VM_LXD_CPU_LIMIT=${VM_LXD_CPU_LIMIT}
VM_LXD_MEMORY_LIMIT=${VM_LXD_MEMORY_LIMIT}
VM_LXD_SAMPLE_CONTAINERS=builder,gateway
VM_INSTALL_DOCKER=yes
SWARM_MODE=init
SWARM_ADVERTISE_ADDR=
SWARM_LISTEN_ADDR=0.0.0.0:2377
SWARM_DEFAULT_OVERLAY_NET=inference-net
SWARM_STACK_FILE=directives/swarm/vllm-stack.yaml
SWARM_STACK_NAME=inference
COLAB_ENABLE=yes
COLAB_RUNTIME_IMAGE=us-docker.pkg.dev/colab-images/public/runtime
COLAB_BIND_ADDRESS=127.0.0.1
COLAB_PORT=9000
COLAB_USE_GPU=${COLAB_USE_GPU}
COLAB_CONTENT_DIR=/srv/colab
COLAB_DOCKER_OPTS=
COLAB_ENABLE_AT_BOOT=yes
GOOGLE_CLOUD_ENABLE=${GOOGLE_CLOUD_ENABLE}
GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
GOOGLE_CLOUD_REGION=${GOOGLE_CLOUD_REGION}
GOOGLE_APPLICATION_CREDENTIALS=/opt/google/service-account.json
GOOGLE_APPLICATION_CREDENTIALS_B64=
GOOGLE_CLOUD_BUCKET=
GOOGLE_CLOUD_AUTH_MODE=adc
INSTALL_GCLOUD_HOST=no
CEPH_ENABLE=${CEPH_ENABLE}
CEPH_CLUSTER_NAME=ceph
CEPH_CLIENT_NAME=client.${CEPH_CLIENT_NAME}
CEPH_MON_HOSTS=${CEPH_MON_HOSTS}
CEPH_CONF_PATH=/etc/ceph/ceph.conf
CEPH_KEYRING_PATH=/etc/ceph/ceph.client.${CEPH_CLIENT_NAME}.keyring
CEPH_CLIENT_KEYRING_B64=
CEPHFS_ENABLE=yes
CEPHFS_NAME=cephfs
CEPHFS_MOUNT=/srv/cephfs
CEPHFS_SUBPATH=/models
CEPHFS_BIND_INTO_LXD=yes
CEPHFS_BIND_INTO_COLAB=yes
RUN_RENDER_DIRECTIVES=yes
RUN_HOST_PREREQS=yes
RUN_HOST_NETWORK=yes
RUN_HOST_LXD=no
RUN_HOST_WIREGUARD=yes
RUN_HOST_CEPH_CLIENT=yes
RUN_VM_DEPLOY=yes
RUN_VM_BOOTSTRAP=yes
RUN_VM_WIREGUARD=yes
RUN_VM_LXD=yes
RUN_VM_DOCKER=yes
RUN_VM_GCLOUD=yes
RUN_VM_CEPH=yes
RUN_VM_COLAB=yes
EOF

log "Wrote ${REPO_ROOT}/.env"
echo
echo "Next:"
echo "  ./bin/exosys-colab.sh render-directives"
echo "  sudo ./bin/exosys-colab.sh up"
