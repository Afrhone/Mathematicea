# LimeSDR Integration

Default target:

```text
factau-rhiz 192.168.0.4
```

The API starts in `SDR_MODE=synthetic`, so the UI works without hardware.

For hardware:

```bash
SoapySDRUtil --find
SoapySDRUtil --probe="driver=lime"
```

LXD USB passthrough example:

```bash
lxc config device add afrho-limesdr-lab limesdr usb vendorid=1d50 productid=6108
```

Keep transmit disabled unless you have legal authorization and a tested RF plan.
