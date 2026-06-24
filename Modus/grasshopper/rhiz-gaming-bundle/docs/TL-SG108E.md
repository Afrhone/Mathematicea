# TL-SG108E: Port 1 ISP, Port 2 Fedora 43, Port 3 MikroTik ether2 (private)

Goal:
- Port 1 -> ISP box (VLAN1)
- Port 2 -> Fedora 43 (private VLAN)
- Port 3 -> MikroTik ether2 (private VLAN)

Recommended: VLAN ID 50 for the private segment.

Steps (UI):
1) VLAN -> 802.1Q VLAN -> Enable
2) Add VLAN 50
3) VLAN membership:
   - VLAN50: Port2=Untagged, Port3=Untagged, Port1=Not Member
   - VLAN1 : Port1=Untagged, Port2=Not Member, Port3=Not Member
4) VLAN -> 802.1Q PVID:
   - Port1 PVID=1
   - Port2 PVID=50
   - Port3 PVID=50
5) Apply/Save
