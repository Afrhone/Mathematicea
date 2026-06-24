#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/modules/00-lib.sh"

usage(){
  cat <<'EOT'
exosys-colab.sh — Fedora + Ubuntu 24.04 + Colab runtime fabric bundle

Usage:
  ./bin/exosys-colab.sh help
  ./bin/exosys-colab.sh discover
  ./bin/exosys-colab.sh wizard
  ./bin/exosys-colab.sh render-directives
  sudo ./bin/exosys-colab.sh host-prereqs
  sudo ./bin/exosys-colab.sh host-lxd
  sudo ./bin/exosys-colab.sh host-network
  sudo ./bin/exosys-colab.sh host-wireguard
  sudo ./bin/exosys-colab.sh host-ceph-client
  sudo ./bin/exosys-colab.sh vm-deploy
  ./bin/exosys-colab.sh vm-wait
  sudo ./bin/exosys-colab.sh vm-bootstrap
  sudo ./bin/exosys-colab.sh vm-wireguard
  sudo ./bin/exosys-colab.sh vm-lxd
  sudo ./bin/exosys-colab.sh vm-docker
  sudo ./bin/exosys-colab.sh vm-gcloud
  sudo ./bin/exosys-colab.sh vm-ceph
  sudo ./bin/exosys-colab.sh vm-colab
  ./bin/exosys-colab.sh smoke
  ./bin/exosys-colab.sh status
  sudo ./bin/exosys-colab.sh up

Notes:
  - discover and wizard are non-root
  - most host and vm actions are root
  - vm-wait and status are safe to run repeatedly
EOT
}

cmd="${1:-help}"

main(){
  case "$cmd" in
    help|-h|--help) usage ;;
    discover) "${REPO_ROOT}/modules/01-discover.sh" ;;
    wizard) "${REPO_ROOT}/modules/02-wizard.sh" ;;
    render-directives) load_env; "${REPO_ROOT}/modules/03-render-directives.sh" ;;
    host-prereqs) require_root; load_env; "${REPO_ROOT}/modules/10-host-prereqs-fedora.sh" ;;
    host-lxd) require_root; load_env; "${REPO_ROOT}/modules/11-host-lxd-install.sh" ;;
    host-network) require_root; load_env; "${REPO_ROOT}/modules/12-host-libvirt-network.sh" ;;
    host-wireguard) require_root; load_env; "${REPO_ROOT}/modules/13-host-wireguard.sh" ;;
    host-ceph-client) require_root; load_env; "${REPO_ROOT}/modules/14-host-ceph-client.sh" ;;
    host-gpu-check) load_env; "${REPO_ROOT}/modules/15-host-gpu-check.sh" ;;
    vm-deploy) require_root; load_env; "${REPO_ROOT}/modules/20-vm-cloud-image.sh" ;;
    vm-wait) load_env; "${REPO_ROOT}/modules/21-vm-wait-ssh.sh" ;;
    vm-bootstrap) require_root; load_env; "${REPO_ROOT}/modules/22-vm-bootstrap-ubuntu.sh" ;;
    vm-wireguard) require_root; load_env; "${REPO_ROOT}/modules/23-vm-wireguard.sh" ;;
    vm-lxd) require_root; load_env; "${REPO_ROOT}/modules/24-vm-lxd.sh" ;;
    vm-docker) require_root; load_env; "${REPO_ROOT}/modules/25-vm-docker-swarm.sh" ;;
    vm-gcloud) require_root; load_env; "${REPO_ROOT}/modules/27-vm-google-cloud.sh" ;;
    vm-ceph) require_root; load_env; "${REPO_ROOT}/modules/28-vm-ceph-mounts.sh" ;;
    vm-colab) require_root; load_env; "${REPO_ROOT}/modules/26-vm-colab-runtime.sh" ;;
    smoke) load_env; "${REPO_ROOT}/modules/29-vm-smoke.sh" ;;
    status) load_env; "${REPO_ROOT}/modules/90-status.sh" ;;
    up)
      require_root
      load_env
      [[ "${RUN_RENDER_DIRECTIVES:-yes}" =~ ^(yes|true|1|auto)$ ]] && "${REPO_ROOT}/modules/03-render-directives.sh"
      [[ "${RUN_HOST_PREREQS:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/10-host-prereqs-fedora.sh"
      [[ "${RUN_HOST_LXD:-no}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/11-host-lxd-install.sh"
      [[ "${RUN_HOST_NETWORK:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/12-host-libvirt-network.sh"
      [[ "${RUN_HOST_WIREGUARD:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/13-host-wireguard.sh"
      [[ "${RUN_HOST_CEPH_CLIENT:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/14-host-ceph-client.sh"
      [[ "${RUN_VM_DEPLOY:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/20-vm-cloud-image.sh"
      "${REPO_ROOT}/modules/21-vm-wait-ssh.sh"
      [[ "${RUN_VM_BOOTSTRAP:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/22-vm-bootstrap-ubuntu.sh"
      [[ "${RUN_VM_WIREGUARD:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/23-vm-wireguard.sh"
      [[ "${RUN_VM_LXD:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/24-vm-lxd.sh"
      [[ "${RUN_VM_DOCKER:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/25-vm-docker-swarm.sh"
      [[ "${RUN_VM_GCLOUD:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/27-vm-google-cloud.sh"
      [[ "${RUN_VM_CEPH:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/28-vm-ceph-mounts.sh"
      [[ "${RUN_VM_COLAB:-yes}" =~ ^(yes|true|1)$ ]] && "${REPO_ROOT}/modules/26-vm-colab-runtime.sh"
      "${REPO_ROOT}/modules/29-vm-smoke.sh"
      ;;
    *)
      die "Unknown command: $cmd (run help)"
      ;;
  esac
}

main "$@"
