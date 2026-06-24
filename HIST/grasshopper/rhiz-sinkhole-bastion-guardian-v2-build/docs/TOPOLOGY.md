# Topology

```text
LAN 192.168.0.0/24

rhiz-ueth 192.168.0.2  ---- allowed ingress/bastion ----> exosys-rhiz 192.168.0.50
    |                                                        |
    | wg-rhiz-sink 10.111.9.2/24                            | wg-rhiz-sink 10.111.9.1/24
    +---------------- WireGuard bastion plane ---------------+
                                                             |
                                                             + rhiz-sink0 / sinkhole0
                                                               10.45.3.1/24
                                                               DNS sinkhole: 10.45.3.53
                                                               DHCP: 10.45.3.100-220
```
