
# Hardware Control Notes

## Browser Gamepad API

Works in modern browsers over HTTPS or localhost. USB and Bluetooth Xbox controllers usually expose standard axes/buttons.

## Linux collector

The collector uses `evdev` and needs `/dev/input` access:

```bash
./scripts/11_up_hardware_collector.sh
```

## LED control

Real Xbox LED color support is not universal. Use `software` mode for the dashboard aura and extend `xpadneo`/`hidraw` only for supported hardware.
