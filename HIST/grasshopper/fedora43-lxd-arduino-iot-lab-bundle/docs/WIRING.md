# Wiring notes

## Uno WiFi Rev2 + BME280

Typical I2C:

| BME280 | Arduino Uno WiFi Rev2 |
|---|---|
| VIN | 3.3V or 5V module-dependent |
| GND | GND |
| SDA | SDA |
| SCL | SCL |

I2C address is usually `0x76` or `0x77`.

## PN532 shield

Use the shield's selected mode. The firmware scaffold assumes I2C if enabled. Avoid powering multiple shields from weak USB hubs.

## BMM150 + AMG8833

Both are I2C. Check address conflicts before combining on one bus. The scaffold probes:

- BMM150: `0x10`
- AMG8833: `0x69`

## Yun Rev2 + 4G LTE GPS shield

Use vendor power guidance. LTE shields can draw high current; do not rely on a weak USB port. The USB tether fallback script is host-side networking, not a magic modem driver for every LTE shield.
