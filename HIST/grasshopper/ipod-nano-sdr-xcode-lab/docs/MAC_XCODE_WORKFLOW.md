# Mac / Xcode Workflow

1. Install Xcode from the Mac App Store or Apple Developer site.
2. Optional: install XcodeGen.

```bash
brew install xcodegen ffmpeg
./scripts/export-to-xcode.sh
./scripts/create-xcode-project.sh
open xcode/NanoSpectroLab/NanoSpectroLab.xcodeproj
```

3. Run Docker server:

```bash
docker compose up --build
```

4. In Xcode, run the app in Simulator. Use `http://localhost:8088` for Simulator.

For a physical iOS/iPod touch device, use your Mac LAN IP instead of localhost, for example:

```text
http://192.168.0.20:8088
```
