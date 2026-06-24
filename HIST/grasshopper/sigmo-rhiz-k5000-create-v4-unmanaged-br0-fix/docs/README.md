# sigmo-rhiz K5000 v4 unmanaged br0 fix

This patch fixes the LXD error:

```text
Cannot use manually specified ipv4.address when using unmanaged parent bridge
```

Reason: `br0` is an unmanaged host bridge. LXD can attach a NIC to it, but cannot reserve `ipv4.address=` on the device. The script now:

1. Adds `eth0` on managed `lxdbr0` with `ipv4.address=10.249.34.126`.
2. Adds `lan0` on unmanaged `br0` **without** `ipv4.address`.
3. Starts the container.
4. Writes static `192.168.0.126/24` inside the container using netplan.
5. Keeps `llama-gpu` protected as the Radeon 16GB worker.

Run:

```bash
cp env/cluster.env .env
nano .env
DEBUG=1 bash scripts/20_create_isolated_k5000_container_v4.sh
bash health/check_k5000_container_v4.sh
```
