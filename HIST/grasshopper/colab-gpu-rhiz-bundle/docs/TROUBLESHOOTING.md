# Troubleshooting

## VM does not get an IP
- Check `virsh net-list --all`
- Check `virsh net-info colab-vm-net`
- Check `sudo journalctl -u libvirtd -b`
- Check `virsh domifaddr <vm> --source lease`
- Ensure the guest agent is running once cloud-init is complete

## Colab runtime service starts but notebook cannot connect
- SSH tunnel to the VM:
  `ssh -L 9000:127.0.0.1:9000 ubuntu@<VM_IP>`
- Inspect the runtime token:
  `sudo journalctl -u colab-runtime -n 100 --no-pager`
- Confirm the service binds to `127.0.0.1:${COLAB_PORT}`

## GPU flag is ignored
- Verify the GPU is actually visible in the guest:
  `lspci -nn | grep -Ei 'nvidia|vga|3d'`
  `nvidia-smi`
- Verify Docker GPU support:
  `sudo docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`
- If that fails, the guest still needs the NVIDIA driver and/or NVIDIA container toolkit

## WireGuard handshake missing
- Check host public IP / endpoint
- Check host firewall UDP port
- Check:
  `sudo wg show`
  `sudo systemctl status wg-quick@wg-colab`

## LXD commands fail after install
- Re-run:
  `sudo lxd waitready`
  `sudo lxd init --preseed < /tmp/vm-lxd-preseed.yaml`
- For non-root use of LXD, the target user may need `usermod -aG lxd <user>` and a new login shell

## Ceph mount fails
- Check mon connectivity:
  `nc -vz <mon> 3300`
  `nc -vz <mon> 6789`
- Check auth files:
  `/etc/ceph/ceph.conf`
  `/etc/ceph/ceph.client.<name>.keyring`
- Confirm the CephFS path and client caps are valid
