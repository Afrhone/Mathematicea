# MikroTik VLAN50 access ports (ether2 + ether5)
/interface bridge port
set [find interface=ether2] pvid=50 frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes
set [find interface=ether5] pvid=50 frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes

/interface bridge vlan
set [find where bridge=bridge vlan-ids=50] tagged=bridge untagged=ether2,ether5

/interface vlan
add name=vlan50 interface=bridge vlan-id=50 disabled=no
/ip address
add address=10.0.0.1/24 interface=vlan50
