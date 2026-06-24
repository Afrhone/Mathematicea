# Positronic Differentiable Turing Machine · WebAssembly

A browser experiment inspired by the linked modular ambient video title: **Bloom, Rings, Magneto, Beads**.

It is not a classical discrete Turing machine. It is a differentiable / neural-style Turing machine:

- `tape[i]` is continuous, not binary.
- `head[i]` is a soft attention distribution over all cells.
- `state[s]` is a soft state vector.
- `logits[state,symbol]` are trainable transition/write weights.
- `error = target - read` drives the update rule.
- Bloom/Rings/Magneto/Beads act as control voltages for write intensity, attention focus, head motion, and diffusion.

## Run

Because browsers block `fetch()` from `file://`, serve the folder:

```bash
cd positronic-turing-wasm
python3 -m http.server 8080
# open http://localhost:8080
```

## Rebuild WASM

```bash
clang --target=wasm32 -O3 -nostdlib \
  -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined \
  -o ptm.wasm src/ptm.c
```

## Files

- `index.html` — UI shell
- `style.css` — cosmic panel styling
- `app.js` — canvas, WebAudio, WASM bridge
- `ptm.wasm` — compiled machine core
- `src/ptm.c` — editable WASM source
