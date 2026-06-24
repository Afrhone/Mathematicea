# GPU Notes

## sigmo-rhiz K5000

- Use for orchestration, light inference, and experimentation.
- Expect modern CUDA containers to fail or fall back due to legacy architecture.
- Keep `nvidia-smi` and Docker runtime checks in the doctor output.

## rhiz-fach RTX 4070 Ti Phoenix / gpu-compute

- Preferred for vLLM and Diffusers.
- Run LXD GPU container or direct Docker GPU stack on the host.
- Expose OpenAI-compatible vLLM on `192.168.0.52:8000`.
- Expose image/Diffusers service on `192.168.0.52:7860`.

## llama-gpu 192.168.0.125

- Preferred for llama.cpp GGUF serving.
- Expose OpenAI-compatible endpoint on `:8088/v1`.
