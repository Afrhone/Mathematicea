
# Architecture

## Planes

- UI/UX plane: Vite dashboard, WebGL controller cosmos, uploaded sketch launcher.
- Hardware plane: browser Gamepad API + optional Linux evdev collector.
- BI plane: telemetry aggregation, drift/stress/symmetry/activity scoring.
- Agent plane: OpenAI-compatible `/v1/chat/completions` gateway, local-first model routing.
- MCP plane: JSON-RPC tool surface for profile, LED, Docker/Swarm status.
- Swarm plane: deployable stack with placement labels.

## Uploaded sketch analysis

The uploaded universe sketch already supports gamepad deadzone, smoothing, response curve, look sensitivity, movement sensitivity, Y inversion, haptics flags, and standard Xbox-style mappings. This bundle extracts that idea into a standalone dashboard profile system and WebGL controller cosmos.

The gravitational lens sketch includes keyboard/gamepad control and a multi-scale lensing simulation. This bundle keeps those sketches as runnable source captures while adding a unified dashboard and API around them.
