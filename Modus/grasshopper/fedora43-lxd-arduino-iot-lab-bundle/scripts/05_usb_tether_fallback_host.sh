#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
[ "$(id -u)" -eq 0 ] || die "Run with sudo"

ENABLE_USB_TETHER_FALLBACK="${ENABLE_USB_TETHER_FALLBACK:-false}"
[ "$ENABLE_USB_TETHER_FALLBACK" = "true" ] || die "Set ENABLE_USB_TETHER_FALLBACK=true in .env to use this."

LAN_IFACE="${LAN_IFACE:-br0}"
USB_TETHER_IFACE="${USB_TETHER_IFACE:-auto}"
TETHER_SHARED_CIDR="${TETHER_SHARED_CIDR:-172.31.77.1/24}"

if [ "$USB_TETHER_IFACE" = "auto" ]; then
  USB_TETHER_IFACE="$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="ethernet"{print $1}' | grep -E 'usb|enx|ww|cdc|rndis' | head -n1 || true)"
fi
[ -n "$USB_TETHER_IFACE" ] || die "No USB tether interface detected. Set USB_TETHER_IFACE=..."

log "Configuring USB tether interface $USB_TETHER_IFACE as shared fallback"
nmcli con delete arduino-usb-tether 2>/dev/null || true
nmcli con add type ethernet ifname "$USB_TETHER_IFACE" con-name arduino-usb-tether ipv4.method shared ipv4.addresses "$TETHER_SHARED_CIDR" ipv6.method ignore
nmcli con up arduino-usb-tether

log "Enable forwarding and masquerade"
sysctl -w net.ipv4.ip_forward=1
firewall-cmd --permanent --add-masquerade || true
firewall-cmd --permanent --zone=trusted --change-interface="$USB_TETHER_IFACE" || true
firewall-cmd --permanent --zone=trusted --add-interface="$LAN_IFACE" || true
firewall-cmd --reload || true

log "USB tether fallback configured"
ip -br a
ip route
