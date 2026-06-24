# Architecture

## Planes

1. **Surface plane**: native WebGL2 canvas in Next.js, responsible for 8D point projection, sphere reflection, shader fog/water/crack layers, labels, and touch/audio interactions.
2. **Signal plane**: browser fetches `/api/network` and streams telemetry from the gateway. Samples become graph nodes, edges, pulses, and anomaly highlights.
3. **Agent plane**: gateway exposes OpenAI-compatible `/v1/chat/completions` and higher-level `/api/analyze-network`. It can route to llama.cpp, Ollama, vLLM, Docker Model Runner, or remote OpenAI-compatible APIs.
4. **Memory plane**: MongoDB stores telemetry, prompts, persona outputs, graph snapshots, and analysis traces.
5. **Compute plane**: optional GPU containers run llama.cpp/Ollama/vLLM. Existing LXD/libvirt/Ceph hosts remain outside the web app but are sampled by the collector.

## 8D projection model

Each node has an 8D latent vector `q`. The renderer normalizes `q` onto an S7 hypersphere, compresses pairwise energy into four complex amplitudes, then maps them to a 3D sphere shell. The shader raymarch layer interprets the same latent energy as a refractive skin: blob blending, caustic water ridges, crack discontinuities, and fog density are all time-varying fields.

## API contracts

- `GET /health`: gateway status.
- `GET /api/network`: latest telemetry graph.
- `POST /api/telemetry`: collector ingest.
- `POST /api/analyze-network`: asks the selected local model for operational interpretation.
- `POST /v1/chat/completions`: OpenAI-compatible proxy.

## Safety gates

Mutating cluster commands are not executed by the web UI. The collector is read-only by default and shells out only to inspect `lxc`, `docker`, `ceph`, `ip`, and `hostname`. Keep deployment tokens private and rotate `COLLECTOR_TOKEN`.
