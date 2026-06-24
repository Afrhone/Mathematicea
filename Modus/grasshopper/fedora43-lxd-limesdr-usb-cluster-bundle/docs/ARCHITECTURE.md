# Architecture

```text
Fedora 43 host / LXD cluster
        |
        | USB LimeSDR-USB physical device
        v
LXD target node, default factau-rhiz
        |
        | LXD usb passthrough
        v
Ubuntu 25.04 container: limesdr-usb-lab
        |
        | LimeSuite, SoapySDR, FastAPI
        v
Probe and spectrogram service
```

The container must run on the same cluster member where the physical LimeSDR-USB is attached.
