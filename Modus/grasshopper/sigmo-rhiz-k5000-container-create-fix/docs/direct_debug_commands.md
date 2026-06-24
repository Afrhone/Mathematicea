# Direct debug commands

```bash
cd ~/sigmo-rhiz-k5000-container-create-fix
cp env/cluster.env .env
bash -n scripts/20_create_isolated_k5000_container_v2.sh
bash health/check_k5000_create_prereqs.sh
DEBUG=1 bash scripts/20_create_isolated_k5000_container_v2.sh
```

If it stops at image download/init:

```bash
lxc image list ubuntu: 24.04
lxc init ubuntu:24.04 llama-k5000-test -s default --debug
```

If target is invalid:

```bash
lxc cluster list
sed -i 's/^LXD_TARGET=.*/LXD_TARGET=/' .env
```

If GPU address is not detected:

```bash
lspci -Dnn | grep -Ei 'nvidia|k5000|gk104'
echo 'NVIDIA_GPU_PCI=0000:0f:00.0' >> .env
```

If 10.83 bridge does not exist:

```bash
lxc network list
sed -i 's/^ENABLE_1083_NET=.*/ENABLE_1083_NET=0/' .env
```
