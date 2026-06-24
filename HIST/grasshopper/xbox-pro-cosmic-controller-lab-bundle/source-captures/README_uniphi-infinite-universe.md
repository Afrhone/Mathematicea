# Uniphi Infinite Universe — single-file sketch (Gamepad enhanced)

Open **uniphi-infinite-universe.html** in a modern browser (Chrome/Edge/Firefox/Safari).

## What it is
A single-canvas WebGL universe with:
- **Infinite starfield** (chunked, deterministic; world follows you to avoid float precision loss)
- **Camera modes**: Cockpit (free-fly), Orbit, Flyby
- **Warp streaks + Nebula fog**
- **Wormhole portal** (radial tunnel + swirl + edge shimmer)
- **Controls**: keyboard/mouse + touch pads + **robust Gamepad API** (deadzone + smoothing)

## Controls (quick)
- **C** cycle camera mode
- **L** lock/unlock pointer (mouse look)
- **WASD** thrust/strafe (Cockpit)
- **R / F** up / down
- **Q / E** roll
- **Shift** boost
- **Space** brake
- **G** toggle wormhole
- **P** save PNG

### Gamepad (standard mapping)
**Cockpit mode**
- **Left Stick**: strafe (X) / thrust (Y)
- **Right Stick**: look (yaw/pitch)
- **RT** throttle forward, **LT** brake/reverse
- **D‑pad Up/Down**: up/down
- **LB/RB**: roll left/right
- **A** boost, **B** brake (hard)
- **X** toggle wormhole, **Y** cycle camera
- **Start** toggle pointer‑lock
- **Back** save PNG

**Orbit mode**
- **Left Stick**: orbit
- **LT/RT**: zoom

## Notes
- Trails are implemented as an in-FBO fade pass; set Trails to 0.00 for crisp frames.
- If you want more density, raise “Stars” but watch GPU fill-rate and blending cost.

Enjoy orbiting the void ✨
