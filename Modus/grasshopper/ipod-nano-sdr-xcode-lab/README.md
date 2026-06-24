# iPod Nano / Xcode / HTML Animation / SDR Spectrogram Lab

This lab creates a complete workflow for:

- running a server-side SDR spectrogram pipeline in Docker,
- serving HTML/WebGL/Canvas animations,
- exporting static HTML/media assets for old iPod nano experiments,
- wrapping the same animation/spectrogram UI in a small Xcode SwiftUI/WebKit app for iOS Simulator/iPod touch/iPhone,
- preparing an iPod nano-compatible asset bundle where realistic.

## Reality boundary

Old iPod nano generations are not iOS devices and do not run arbitrary Xcode-built apps. Xcode can build for iPhone/iPod touch/iPad/macOS, but not classic click-wheel or nano firmware. This bundle therefore provides two paths:

1. **Nano asset path:** export HTML/MP4/GIF/images/audio that can be synced as media where the nano generation supports it.
2. **Xcode app path:** build a WebView wrapper for iOS Simulator, iPhone, or iPod touch. Use this for interactive HTML animation and live SDR spectrogram viewing.

## Quick start

```bash
cp .env.example .env
./scripts/doctor.sh
./scripts/build-docker.sh
./scripts/up.sh
```

Open:

- HTML lab: http://localhost:8088
- SDR API: http://localhost:8090
- latest spectrogram frame: http://localhost:8090/spectrogram.png
- WebSocket stream: ws://localhost:8090/ws

## Export to Xcode/macOS

```bash
./scripts/export-to-xcode.sh
open xcode/NanoSpectroLab/NanoSpectroLab.xcodeproj
```

In Xcode, select a simulator or real iOS/iPod touch device and run.

## RTL-SDR input

Default mode is synthetic IQ so the lab runs everywhere. For real RTL-SDR:

```bash
SDR_MODE=rtlsdr docker compose up --build
```

You may need USB pass-through to Docker Desktop or run the SDR server directly on Linux.
