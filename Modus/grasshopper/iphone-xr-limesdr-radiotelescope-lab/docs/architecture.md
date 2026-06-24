# Architecture

```text
iPhone XR
  ├── Safari Web App / optional native wrapper
  ├── camera frames / video app stream over Wi-Fi
  ├── motion/orientation/battery/GPS telemetry
  └── feedback display/audio/haptic cues
          │
          ▼
LXD VM / Docker server
  ├── FastAPI ingest + WebSocket
  ├── spectrogram generator
  ├── lens and astronomy math service
  ├── LimeSDR worker through SoapySDR
  ├── MCP-compatible tool bridge
  └── optional local model gateway
          │
          ▼
LimeSDR / radiotelescope hardware
  ├── 21 cm hydrogen line experiments
  ├── FFT/waterfall analysis
  └── event/rhythm/anomaly telemetry
```

The phone is a sensor/camera/controller. LimeSDR belongs on the server side because iOS does not provide generic USB host SDR access in this workflow.
