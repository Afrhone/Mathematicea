# Architecture

```text
radio / synthetic IQ
       │
       ▼
Docker SDR server ── /spectrogram.png, /stats, /ws
       │
       ├── browser HTML animation target
       ├── Xcode SwiftUI + WKWebView wrapper
       └── nano media export: MP4/GIF/stills/audio sync
```

## Components

- `docker/sdr-server`: FastAPI service generating a rolling spectrogram.
- `assets/html-animation`: WebGL2 animated interface with SDR pulse coupling.
- `xcode/NanoSpectroLab`: SwiftUI/WebKit wrapper sources and XcodeGen spec.
- `scripts/export-nano-media.sh`: creates legacy-friendly media assets.

## Device strategy

Classic iPod nano devices are media players, not iOS app targets. The lab exports media and static assets for nano sync. Interactive UI runs in browser, iOS Simulator, iPhone, or iPod touch.
