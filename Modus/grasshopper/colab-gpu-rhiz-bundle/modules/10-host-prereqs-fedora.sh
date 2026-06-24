#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd dnf

pkgs=(
  qemu-kvm
  libvirt
  virt-install
  cloud-utils
  genisoimage
  guestfs-tools
  python3-pyyaml
  jq
  curl
  firewalld
  wireguard-tools
  sshpass
  rsync
  lxc
  snapd
  ceph-common
)

log "Installing Fedora host prerequisites"
dnf install -y "${pkgs[@]}"

systemctl enable --now libvirtd
systemctl enable --now firewalld
systemctl enable --now snapd.socket || true
[[ -e /snap ]] || ln -snf /var/lib/snapd/snap /snap

if id -nG "${SUDO_USER:-$(whoami)}" | grep -qw libvirt; then
  :
else
  usermod -aG libvirt "${SUDO_USER:-$(whoami)}" || true
  warn "Added ${SUDO_USER:-$(whoami)} to libvirt group; a new login shell may be needed."
fi

if is_yes "${INSTALL_GCLOUD_HOST:-no}"; then
  if [[ ! -f /etc/yum.repos.d/google-cloud-cli.repo ]]; then
    cat > /etc/yum.repos.d/google-cloud-cli.repo <<'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  fi
  dnf install -y google-cloud-cli || warn "Could not install google-cloud-cli on Fedora host"
fi

log "Host prerequisites complete"
