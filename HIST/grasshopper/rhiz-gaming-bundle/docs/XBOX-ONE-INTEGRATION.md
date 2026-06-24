# Local Xbox One integration

## Supported lanes in this bundle

### 1) Official Xbox Cloud Gaming on the console
Use the local Xbox One exactly as Microsoft intends for Xbox catalog cloud titles.
This is separate from your self-hosted VM.

### 2) Moonlight on Xbox for the self-hosted Windows VM
The practical self-hosted path is:

- Windows 11 gaming VM on Fedora/libvirt
- Sunshine host software inside the Windows VM
- Moonlight client on the Xbox One

This gives you a console-like endpoint for your own Windows VM while keeping your gaming horsepower in the KVM host.

### 3) Official Xbox Remote Play for the physical console
Keep this available if you want to stream the **physical Xbox One** to other devices.
That is different from streaming the Windows gaming VM.

## Not supported / not recommended

- Treating the Xbox One as a libvirt guest host
- Treating the Xbox One as an LXD node
- Treating the Xbox One GPU as part of a cluster GPU pool
- Expecting Xbox Cloud Gaming SDK components to turn your own Ceph/KVM cluster into xCloud
