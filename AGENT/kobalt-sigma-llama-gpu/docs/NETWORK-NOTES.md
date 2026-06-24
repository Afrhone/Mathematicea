# Network notes

If raw IP connectivity works but `apt` to Ubuntu mirrors hangs or fails, do not block the whole deployment on `apt`.

This bundle keeps the **runtime path** mostly independent of `apt` by using:
- manual Ollama tarball install
- optional Docker compose artifacts
- a generic Ollama GGUF import path

You only need `apt` for the native `llama.cpp` build path.
