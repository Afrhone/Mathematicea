# USB tether fallback

The script `scripts/05_usb_tether_fallback_host.sh` configures a detected USB Ethernet/RNDIS/CDC interface as a shared connection using NetworkManager.

It is disabled by default. Enable only after identifying the interface:

```bash
nmcli dev
ip -br link
```

Then set:

```env
ENABLE_USB_TETHER_FALLBACK=true
USB_TETHER_IFACE=enx...
LAN_IFACE=br0
```

Run:

```bash
sudo bash scripts/05_usb_tether_fallback_host.sh
```

Rollback:

```bash
sudo nmcli con delete arduino-usb-tether
sudo firewall-cmd --permanent --remove-masquerade
sudo firewall-cmd --reload
```
