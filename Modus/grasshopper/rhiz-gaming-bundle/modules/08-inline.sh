#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
phase="${1:-}"
[[ -n "$phase" ]] || die "Usage: inline <bootstrap-hosts|ceph-base|libvirt-base|guest-niurk24|swarm-base|all>"
case "$phase" in
  bootstrap-hosts) sudo "${REPO_ROOT}/bin/exosys-remote.sh" bootstrap-all ;;
  ceph-base) sudo "${REPO_ROOT}/bin/exosys.sh" ceph-bootstrap; sudo "${REPO_ROOT}/bin/exosys.sh" ceph-core-place ;;
  libvirt-base) sudo "${REPO_ROOT}/bin/exosys.sh" libvirt-ceph-secret; sudo "${REPO_ROOT}/bin/exosys.sh" libvirt-storage-define; sudo "${REPO_ROOT}/bin/exosys.sh" libvirt-host-pools-apply ;;
  guest-niurk24) sudo "${REPO_ROOT}/bin/exosys.sh" vm-profile-launch niurk-24 gpu-fedora sigmo-rhiz; sudo "${REPO_ROOT}/bin/exosys.sh" guest-bootstrap-ubuntu niurk-24 ;;
  swarm-base) sudo "${REPO_ROOT}/bin/exosys.sh" swarm-init pi-rhiz; sudo "${REPO_ROOT}/bin/exosys.sh" swarm-join factau-rhiz manager ;;
  all) sudo "${REPO_ROOT}/bin/exosys.sh" inline bootstrap-hosts; sudo "${REPO_ROOT}/bin/exosys.sh" inline ceph-base; sudo "${REPO_ROOT}/bin/exosys.sh" inline libvirt-base ;;
  *) die "Unknown phase: $phase" ;;
esac
