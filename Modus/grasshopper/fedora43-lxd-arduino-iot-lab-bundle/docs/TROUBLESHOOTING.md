# Troubleshooting

## Container has no USB devices

```bash
ls -lah /dev/serial/by-id
bash scripts/04_attach_usb_devices.sh
lxc exec arduino-iot-lab -- ls -lah /dev/arduino-* /dev/ttyACM* /dev/ttyUSB*
```

## Arduino image cannot be found

Check your remotes:

```bash
lxc image info ubuntu:25.04
lxc image info images:ubuntu/25.04
```

Set `LXD_IMAGE` to the one that resolves.

## Ceph storage issue

```bash
lxc storage show rhiz-storage
lxc storage volume list rhiz-storage
```

## Docker inside LXD

The profile enables nesting. If Docker fails, inspect:

```bash
lxc config show arduino-iot-lab --expanded
lxc exec arduino-iot-lab -- journalctl -u docker -n 80 --no-pager
```
