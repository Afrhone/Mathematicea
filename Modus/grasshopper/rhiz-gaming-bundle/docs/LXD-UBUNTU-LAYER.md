# LXD / LXC layer

Use this layer on Ubuntu guests (`niurk-24`, `niurk-43`) and the Ubuntu Raspberry Pi manager (`pi-rhiz`).

Typical flow:

```bash
sudo ./bin/exosys.sh guest-bootstrap-ubuntu niurk-24
sudo ./bin/exosys.sh lxd-cluster-init niurk-24
sudo ./bin/exosys.sh lxd-cluster-join niurk-43
sudo ./bin/exosys.sh lxd-cluster-join pi-rhiz
sudo ./bin/exosys.sh lxd-profiles-apply
```
