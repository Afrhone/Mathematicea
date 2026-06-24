# Hardware and IO Map

## EEG

Supported scaffold modes:

```text
mock       = synthetic signal
serial     = generic serial EEG text/CSV bridge
lsl        = future Lab Streaming Layer adapter
openbci    = future OpenBCI adapter placeholder
muse       = future Muse adapter placeholder
```

## AR/VR

Recommended interface targets:

```text
WebXR headset/browser
game controller
keyboard/mouse
camera pose stream
audio input spectrum
```

## Cluster IO

```text
LXD      → lab VM/container
Ceph/RBD → persistence substrate
Docker   → service runtime
Gateway  → only external ingress
Sinks    → evidence memory
```

## Safety

- isolate hardware devices by group permissions
- expose serial/USB only to trusted containers
- do not expose LXD socket to untrusted workloads
- do not treat EEG as medical data unless full compliance exists
