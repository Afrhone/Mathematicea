# Surface Holography Hypercluster

A runnable math generator and visual compute engine for:

```text
_Agent|ik-nn HypergraphGraph Meta Cluster
x <operand_theta_g_df_octonion> |hypercomplex|
"Surface Holography" | φ tensor Ax(t,s,p) ↔ spherical coordinates
quantum superposed states ↔ entangled supersymmetry/asymmetry tick hash field
coupling electromagnetic curl and divergence
extended to cosmological local-cluster bubble symmetry
```

The bundle contains two launch paths:

1. **Vite app** with modular source, WebGPU compute path, CPU fallback, and Three.js/WebGL rendering.
2. **`standalone.html`** single-file CPU/WebGL/Three.js sketch for fast local launch.

> WebGPU compute is experimental here because WebGPU storage buffers cannot be rendered directly by the default Three.js WebGL renderer. The app computes on WebGPU, reads the buffer back to CPU, then updates a Three.js point cloud. For maximum FPS, keep resolution moderate or use the CPU path.

## Run

```bash
cd surface-holography-hypercluster
npm install
npm run dev
```

Then open the local URL printed by Vite.

Standalone quick launch:

```bash
cd surface-holography-hypercluster
python3 scripts/serve.py
# open http://127.0.0.1:8080/standalone.html
```

Do not open the files directly with `file://`; browsers require `localhost` or HTTPS for WebGPU, module imports, and secure graphics features.

## Files

```text
index.html                         Vite entry
standalone.html                    single-file CPU/WebGL visual sketch
src/main.js                        UI + engine bootstrap
src/core/MathGenerator.js          math model + CPU field generator
src/core/HyperComplex.js           spherical, octonion, tick hash, curl/div helpers
src/core/TurnEngine.js             frame/tick scheduler
src/compute/WebGPUCompute.js       WebGPU compute wrapper + readback
src/shaders/holography.compute.wgsl WGSL compute shader
src/render/ThreeSurfaceRenderer.js Three.js point-cloud renderer
examples/params.cosmological-bubble.json tuned preset
scripts/serve.py                   localhost static server
```

## Model map

The visual field treats the surface as a dynamic holographic spherical tensor:

```text
θ, φ  → spherical coordinate domain
Ax(t,s,p) → vector-potential-like field signal
Ψ      → superposed wave stack
Ξ      → entangled tick hash pair field
O      → octonion phase fold from <operand_theta_g_df_octonion>
Λ      → cosmological local-cluster bubble symmetry
∇×A    → curl proxy, rendered as swirl and blue/green energy
∇·A    → divergence proxy, rendered as radial compression/expansion
```

Radius equation:

```text
r = 1 + A · [
  H·Ax(t,s,p)
  + E·Ξ(pair,tick)
  + SUSY·ΣΨ
  - ASYM·|ξ|
  + B·Λcluster
  + C·tanh(|∇×A|)
  + D·tanh(∇·A)
]
```

## Controls

- **Resolution**: point grid density over the sphere.
- **Amplitude**: radial deformation scale.
- **Surface holography H**: strength of Ax tensor surface mapping.
- **Entangled tick hash E**: pair-coupled pseudo-quantum state jitter.
- **Supersymmetry Σ**: coherent superposition stack.
- **Asymmetry Ω**: entropy-like symmetry breaking.
- **Local-cluster bubble Λ**: cosmological bubble shell modulation.
- **EM curl ∇×A**: swirl vector proxy.
- **EM divergence ∇·A**: radial source/sink proxy.
- **operand θ / df/octonion fold**: hypercomplex phase steering.

## Extend it

Add new terms inside `src/core/MathGenerator.js` and mirror them in `src/shaders/holography.compute.wgsl` if you want the WebGPU path to match the CPU path.

Good next modules:

- true finite-difference curl/divergence on the grid,
- WebGPU-native rendering via Three.js WebGPURenderer or raw WebGPU,
- agent state buffers for ik-nn neighbor relaxation,
- hypergraph adjacency texture for edge-coupled fields,
- export frames to PNG or WebM.
