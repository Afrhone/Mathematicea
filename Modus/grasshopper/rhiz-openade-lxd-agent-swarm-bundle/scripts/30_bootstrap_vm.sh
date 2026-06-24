#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
tar -C "$BUNDLE_DIR" -czf /tmp/rhiz-openade-lab.tgz .
lxc exec "$RHIZ_LAB_NAME" -- mkdir -p /opt/rhiz-openade-lab
cat /tmp/rhiz-openade-lab.tgz | lxc exec "$RHIZ_LAB_NAME" -- tar -xz -C /opt/rhiz-openade-lab
rm -f /tmp/rhiz-openade-lab.tgz
lxc exec "$RHIZ_LAB_NAME" -- bash -lc 'cd /opt/rhiz-openade-lab && bash scripts/31_vm_install_base.sh && bash scripts/32_install_electron_evm.sh && bash scripts/33_clone_openade.sh'
