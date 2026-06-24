# Troubleshooting

## Image alias fails

```bash
lxc image info ubuntu:25.04
lxc image list ubuntu:25.04
```

If this fails, try `LXD_IMAGE=images:ubuntu/25.04` in `.env`.

## USB visible on host but not in container

```bash
lsusb
lxc config device show limesdr-usb-lab
lxc exec limesdr-usb-lab -- lsusb
```

Reattach:

```bash
bash scripts/04_attach_limesdr_usb.sh
```

## Package install fails

Run the source build fallback:

```bash
lxc exec limesdr-usb-lab -- /root/build_limesuite_from_source.sh
```

## Ceph storage fails

```bash
lxc storage show rhiz-storage
ceph -s
```
