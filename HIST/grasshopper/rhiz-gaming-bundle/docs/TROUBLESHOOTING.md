# Troubleshooting

## Ceph host add hangs

- verify plain WireGuard reachability first
- verify SSH reachability using the user configured for cephadm
- verify the target hostname matches the name passed to `ceph orch host add`

## Non-root cephadm user

If using a non-root cephadm SSH user, install the cephadm public key into that user's `authorized_keys` and grant passwordless sudo before running `ceph cephadm set-user <user>`.

## libvirt storage pools

If `libvirt-storage-define` fails, verify:

- the Ceph libvirt secret exists
- the target Ceph pool exists and `rbd pool init` was run
- the host can resolve or reach the monitor address used in `directives/libvirt-storage.yaml`


## ceph-host-prepare seems to hang at sudo

If `ceph-host-prepare <host> inventory-user` pauses after connecting, it is usually waiting for a **remote sudo password**. Cephadm's non-root host-management flow requires the target user to already have passwordless sudo. The helper now stops early by default when `sudo -n true` fails, after installing the Cephadm public key into the target user's `authorized_keys`.

Options:

- Run once on the target host as the inventory user:

  ```bash
  echo '<user> ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/99-<user>-cephadm >/dev/null
  sudo chmod 440 /etc/sudoers.d/99-<user>-cephadm
  sudo hostnamectl set-hostname <inventory-name>
  ```

- Then rerun `sudo ./bin/exosys.sh ceph-host-prepare <host> inventory-user` or go straight to `sudo ./bin/exosys.sh ceph-host-add <host>`.
- If you do want the helper to prompt remotely for sudo, set `CEPH_HOST_PREP_ALLOW_INTERACTIVE_SUDO=yes` in `.env` or your shell before running it.
