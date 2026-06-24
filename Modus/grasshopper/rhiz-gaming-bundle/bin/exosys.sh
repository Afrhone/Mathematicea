#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/modules/00-lib.sh"
usage(){
cat <<'EOT'
exosys.sh — Rhiz Cascade Orchestrator

Core:
  ./bin/exosys.sh discover
  ./bin/exosys.sh wizard
  ./bin/exosys.sh inline <phase>
  ./bin/exosys.sh host-profile-render <host> [out-file]
  sudo ./bin/exosys.sh host-profile-apply <host>
  sudo ./bin/exosys.sh prereqs
  sudo ./bin/exosys.sh wg-apply | wg-remove
  ./bin/exosys.sh wg-status
  sudo ./bin/exosys.sh gateway-apply
  sudo ./bin/exosys.sh gateway-token-generate [name]
  sudo ./bin/exosys.sh gateway-remote-config [json-file]
  ./bin/exosys.sh ssh-config-render [out-file]
  ./bin/exosys.sh remote-bootstrap <host>

Ceph:
  sudo ./bin/exosys.sh ceph-bootstrap
  sudo ./bin/exosys.sh ceph-target-accept-key <copied-pubkey-path>
  sudo ./bin/exosys.sh ceph-host-prepare <host> [root|inventory-user]
  sudo ./bin/exosys.sh ceph-host-add <host>
  sudo ./bin/exosys.sh ceph-host-drain-rm <host>
  sudo ./bin/exosys.sh ceph-join-all
  sudo ./bin/exosys.sh ceph-core-place
  sudo ./bin/exosys.sh ceph-compute-pools-apply
  sudo ./bin/exosys.sh ceph-device-list [host]
  sudo ./bin/exosys.sh ceph-osd
  sudo ./bin/exosys.sh ceph-osd-spec-apply [spec-file]
  sudo ./bin/exosys.sh ceph-pool-create [pool] [pg_num]
  sudo ./bin/exosys.sh ceph-pool-auth
  sudo ./bin/exosys.sh rbd-create <image> [size]

libvirt / VM:
  sudo ./bin/exosys.sh libvirt-ceph-secret
  sudo ./bin/exosys.sh libvirt-storage-define
  sudo ./bin/exosys.sh libvirt-host-pools-apply
  sudo ./bin/exosys.sh rbd-attach <vm> <rbd_image> <target_dev>
  sudo ./bin/exosys.sh vm-ubuntu-cloud <vm-name> [cloud-image]
  sudo ./bin/exosys.sh vm-profile-launch <vm-name> <profile-name> [host]
  sudo ./bin/exosys.sh vm-migrate-shared <vm> <dest-uri>
  sudo ./bin/exosys.sh gpu-attach-pci <vm> <bdf>
  sudo ./bin/exosys.sh gpu-attach-mdev <vm> <mdev-uuid>
  ./bin/exosys.sh gpu-check
  sudo ./bin/exosys.sh vm-dump <vm>
  sudo ./bin/exosys.sh guest-bootstrap-ubuntu <guest>

Windows gaming / Xbox:
  sudo ./bin/exosys.sh windows-gaming-check
  sudo ./bin/exosys.sh windows-gaming-render [vm-name]
  sudo ./bin/exosys.sh windows-gaming-create [vm-name]
  ./bin/exosys.sh xbox-integration-render [vm-name]

LXD / LXC:
  sudo ./bin/exosys.sh lxd-cluster-init <node>
  sudo ./bin/exosys.sh lxd-cluster-join <node>
  sudo ./bin/exosys.sh lxd-storage-apply
  sudo ./bin/exosys.sh lxd-profiles-apply

Docker Swarm:
  sudo ./bin/exosys.sh swarm-init <node>
  sudo ./bin/exosys.sh swarm-join <node> [manager|worker]
  ./bin/exosys.sh swarm-stack-render <stack>
  sudo ./bin/exosys.sh swarm-stack-deploy <stack>

Misc:
  ./bin/exosys.sh status
EOT
}
cmd="${1:-help}"
load_env
case "$cmd" in
  help|-h|--help) usage ;;
  discover) "${REPO_ROOT}/modules/04-discover.sh" ;;
  wizard) "${REPO_ROOT}/bin/rhiz-wizard.sh" ;;
  inline) "${REPO_ROOT}/modules/08-inline.sh" "${2:-}" ;;
  host-profile-render) "${REPO_ROOT}/modules/05-host-profile-render.sh" "${2:-}" "${3:-}" ;;
  host-profile-apply) require_root; "${REPO_ROOT}/modules/06-host-profile-apply.sh" "${2:-}" ;;
  prereqs) require_root; "${REPO_ROOT}/modules/10-prereqs.sh" ;;
  wg-apply) require_root; "${REPO_ROOT}/modules/20-wg-nm-apply.sh" ;;
  wg-remove) require_root; "${REPO_ROOT}/modules/22-wg-remove.sh" ;;
  wg-status) "${REPO_ROOT}/modules/21-wg-status.sh" ;;
  gateway-apply) require_root; "${REPO_ROOT}/modules/23-public-gateway-apply.sh" ;;
  gateway-token-generate) require_root; "${REPO_ROOT}/modules/72-gateway-token-generate.sh" "${2:-}" ;;
  gateway-remote-config) require_root; "${REPO_ROOT}/modules/73-gateway-remote-config.sh" "${2:-}" ;;
  ssh-config-render) "${REPO_ROOT}/modules/24-ssh-config-render.sh" "${2:-}" ;;
  remote-bootstrap) "${REPO_ROOT}/modules/25-remote-bootstrap.sh" "${2:-}" ;;
  ceph-bootstrap) require_root; "${REPO_ROOT}/modules/30-ceph-bootstrap.sh" ;;
  ceph-target-accept-key) require_root; "${REPO_ROOT}/modules/31a-ceph-target-accept-key.sh" "${2:-}" ;;
  ceph-host-prepare) require_root; "${REPO_ROOT}/modules/31b-ceph-host-prepare.sh" "${2:-}" "${3:-}" ;;
  ceph-host-add) require_root; "${REPO_ROOT}/modules/31-ceph-host-add.sh" "${2:-}" ;;
  ceph-host-drain-rm) require_root; "${REPO_ROOT}/modules/36-ceph-host-drain-rm.sh" "${2:-}" ;;
  ceph-join-all) require_root; "${REPO_ROOT}/modules/34-ceph-join-all.sh" ;;
  ceph-core-place) require_root; "${REPO_ROOT}/modules/35-ceph-core-place.sh" ;;
  ceph-compute-pools-apply) require_root; "${REPO_ROOT}/modules/38-ceph-compute-pools-apply.sh" ;;
  ceph-device-list) require_root; "${REPO_ROOT}/modules/32b-ceph-device-list.sh" "${2:-}" ;;
  ceph-pool-create) require_root; "${REPO_ROOT}/modules/33a-ceph-pool-create.sh" "${2:-}" "${3:-}" ;;
  ceph-pool-auth) require_root; "${REPO_ROOT}/modules/33-ceph-pool-auth.sh" ;;
  ceph-osd) require_root; "${REPO_ROOT}/modules/32-ceph-osd.sh" ;;
  ceph-osd-spec-apply) require_root; "${REPO_ROOT}/modules/32a-ceph-osd-spec-apply.sh" "${2:-}" ;;
  rbd-create) require_root; "${REPO_ROOT}/modules/41-rbd-create.sh" "${2:-}" "${3:-}" ;;
  libvirt-ceph-secret) require_root; "${REPO_ROOT}/modules/42-libvirt-ceph-secret.sh" ;;
  libvirt-storage-define) require_root; "${REPO_ROOT}/modules/42a-libvirt-storage-define.sh" ;;
  libvirt-host-pools-apply) require_root; "${REPO_ROOT}/modules/39-libvirt-host-pools-apply.sh" ;;
  rbd-attach) require_root; "${REPO_ROOT}/modules/43-libvirt-rbd-attach.sh" "${2:-}" "${3:-}" "${4:-}" ;;
  vm-ubuntu-cloud) require_root; "${REPO_ROOT}/modules/44-libvirt-vm-ubuntu-cloud.sh" "${2:-}" "${3:-}" ;;
  vm-profile-launch) require_root; "${REPO_ROOT}/modules/44a-libvirt-vm-profile-launch.sh" "${2:-}" "${3:-}" "${4:-}" ;;
  vm-migrate-shared) require_root; "${REPO_ROOT}/modules/45-libvirt-vm-migrate-shared.sh" "${2:-}" "${3:-}" ;;
  gpu-attach-pci) require_root; "${REPO_ROOT}/modules/47-libvirt-gpu-attach-pci.sh" "${2:-}" "${3:-}" ;;
  gpu-attach-mdev) require_root; "${REPO_ROOT}/modules/48-libvirt-gpu-attach-mdev.sh" "${2:-}" "${3:-}" ;;
  gpu-check) "${REPO_ROOT}/modules/46-gpu-check.sh" ;;
  vm-dump) require_root; "${REPO_ROOT}/modules/70-vm-dump.sh" "${2:-}" ;;
  guest-bootstrap-ubuntu) require_root; "${REPO_ROOT}/modules/49-guest-bootstrap-ubuntu.sh" "${2:-}" ;;
  windows-gaming-check) require_root; "${REPO_ROOT}/modules/50-windows-gaming-check.sh" ;;
  windows-gaming-render) require_root; "${REPO_ROOT}/modules/49b-windows-gaming-artifacts-render.sh" "${2:-}" ;;
  windows-gaming-create) require_root; "${REPO_ROOT}/modules/44b-libvirt-vm-windows-gaming.sh" "${2:-}" ;;
  xbox-integration-render) "${REPO_ROOT}/modules/51-xbox-integration-render.sh" "${2:-}" ;;
  lxd-cluster-init) require_root; "${REPO_ROOT}/modules/55-lxd-cluster-init.sh" "${2:-}" ;;
  lxd-cluster-join) require_root; "${REPO_ROOT}/modules/56-lxd-cluster-join.sh" "${2:-}" ;;
  lxd-storage-apply) require_root; "${REPO_ROOT}/modules/57-lxd-storage-apply.sh" ;;
  lxd-profiles-apply) require_root; "${REPO_ROOT}/modules/58-lxd-profiles-apply.sh" ;;
  swarm-init) require_root; "${REPO_ROOT}/modules/60-swarm-init.sh" "${2:-}" ;;
  swarm-join) require_root; "${REPO_ROOT}/modules/61-swarm-join.sh" "${2:-}" "${3:-}" ;;
  swarm-stack-render) "${REPO_ROOT}/modules/62-swarm-stack-render.sh" "${2:-}" ;;
  swarm-stack-deploy) require_root; "${REPO_ROOT}/modules/63-swarm-stack-deploy.sh" "${2:-}" ;;
  status) "${REPO_ROOT}/modules/90-status.sh" ;;
  *) die "Unknown command: $cmd" ;;
esac
