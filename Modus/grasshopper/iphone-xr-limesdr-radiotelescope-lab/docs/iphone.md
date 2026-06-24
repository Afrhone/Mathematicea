# iPhone XR integration

Primary mode:

- Safari opens `/phone`.
- Camera permission gives video preview.
- DeviceMotion/DeviceOrientation emit sensor telemetry.
- WebSocket returns feedback cues.

For production video:

- Use an iOS app capable of RTSP/SRT/NDI/HLS streaming.
- Set `VIDEO_INGEST_URL` in `.env`.
- Keep the browser telemetry page open for orientation and feedback.

Bluetooth limitation:

- iOS Safari does not expose a general-purpose BLE API like Chrome on Android/desktop.
- Use Wi-Fi/WebSocket for reliable telemetry.
