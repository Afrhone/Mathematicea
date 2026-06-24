# Architecture

```text
iPhone / Browser / VR headset
        |
        v
Next.js WebGL Realm UI  <---- WebSocket telemetry
        |
        v
FastAPI API + Spectrogram + Functor Engine
        |
        +---- LimeSDR / SoapySDR node on factau-rhiz
        +---- EEG bridge / OSC
        +---- GNN worker
        +---- MCP tool registry
        +---- Agent gateway
        |
        v
Mongo / Redis / files / graph snapshots
```

The engine array is organized as a functor pipeline:

```text
Instrument stream -> metric tensor toy -> graph state -> shader uniforms -> agent commentary
```

The system is built to run locally first and be deployed through Docker Compose, Swarm, or LXD.
