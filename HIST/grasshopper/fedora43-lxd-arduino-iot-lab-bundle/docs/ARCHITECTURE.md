# Architecture

```text
Fedora 43 host / LXD cluster
 ├─ Ceph pool: rhiz-storage
 ├─ LXD container: arduino-iot-lab / Ubuntu 25.04
 │   ├─ USB serial passthrough: /dev/arduino-*
 │   ├─ Docker nested stack
 │   │   ├─ iot-api FastAPI
 │   │   ├─ Next.js live canvas UI
 │   │   ├─ MQTT / Redis / MongoDB
 │   │   └─ MCP KiCad bridge
 │   └─ arduino-cli for compile/upload
 ├─ Optional USB tether fallback
 └─ firewalld allowlist for LAN/mesh
```

The lab separates hardware transport, API normalization, live visualization, and design automation. The KiCad MCP bridge only scaffolds designs; an operator validates the schematic, footprints, isolation, power, RF, and safety before fabrication.
