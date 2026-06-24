# Colab GPU Rhiz Bundle

Deploy an **Ubuntu 24.04 libvirt VM on a Fedora host**, bootstrap a **Colab local runtime**, enable **WireGuard**, **LXD/LXC**, **Docker Swarm**, and optional **CephFS / Ceph RBD-aware storage paths** for shared model and artifact access.

This bundle follows the architecture that fits Colab best:

- **Fedora host**: libvirt/KVM, firewalld, optional host-side LXD, WireGuard endpoint, optional Ceph client
- **Ubuntu 24.04 VM**: Colab runtime container, Docker Swarm manager or worker, LXD for CPU containers, optional CephFS mount, optional Google Cloud CLI + ADC/service account
- **Ceph**: shared storage fabric for images, artifacts, notebooks, model caches, logs
- **Google Cloud**: CLI + ADC / service account wiring for notebooks and containers

## What this bundle does

- Discovers host network / KVM state and generates a `.env`
- Creates a dedicated libvirt NAT network
- Deploys an Ubuntu 24.04 cloud-image VM
- Optionally attaches PCI GPU devices at install time if you already prepared VFIO/IOMMU
- Bootstraps the VM over SSH
- Configures a host↔VM WireGuard tunnel
- Installs and initializes LXD in the VM for CPU-only LXC containers
- Initializes Docker Swarm or joins an existing one
- Installs Google Cloud CLI and wires ADC/service-account auth
- Mounts CephFS in the VM and bind-mounts it into LXD containers
- Runs the official Colab runtime image under systemd on the VM

## Quick path

```bash
cp env.example .env
./bin/exosys-colab.sh discover
./bin/exosys-colab.sh wizard
sudo ./bin/exosys-colab.sh up
./bin/exosys-colab.sh status
```

After `up`, inspect the Colab token URL:

```bash
ssh -L 9000:127.0.0.1:9000 ubuntu@<VM_IP>
ssh ubuntu@<VM_IP> 'sudo journalctl -u colab-runtime -n 50 --no-pager'
```

In Colab:
**Connect → Connect to local runtime** and paste the `http://127.0.0.1:9000/?token=...` URL that appears in the service log.

## Main commands

```bash
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
```

## Important caveats

- **Ceph does storage, not GPU passthrough.** Use Ceph for shared disk / model / artifact paths; use **VFIO or network inference** for GPU access.
- **GPU in the VM** requires your host to already be prepared for IOMMU/VFIO and, inside the guest, NVIDIA drivers may still need to be installed.
- **Colab runtime container** works best bound to `127.0.0.1` and reached through SSH port forwarding.
- **Host-side LXD on Fedora** is installed via `snapd` in this bundle because that is the recommended LXD installation path; Fedora RPM packages for LXD are unofficial/minimally tested.

Read:
- `docs/ARCHITECTURE.md`
- `docs/TROUBLESHOOTING.md`
- `docs/ROLLBACK.md`
