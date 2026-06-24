# Kobalt Sigma llama-gpu Ubuntu 24 Bundle

This bundle targets an **Ubuntu 24 LXD/Incus container** like `llama-gpu` with:

- GPU passthrough already attached from LXD
- a shared models path at `/srv/ollama/models`
- either direct container IP access or a host-side LXD proxy device
- a Kobalt Sigma app tree already present, or cloned separately

It gives you three deployable layers:

1. **Ollama** installed manually from the official Linux tarballs, avoiding `apt` for the runtime itself.
2. **llama.cpp server** in either native build mode or Docker CUDA server mode.
3. **Kobalt Sigma** service wiring, with an environment file and a systemd unit.

## What this bundle assumes

- The container already has working outbound HTTPS to at least `ollama.com`, `github.com`, and your chosen model source.
- The container already has a passed-through GPU device in LXD.
- `/srv/ollama/models` exists or can be created.

## Fast path

Inside `llama-gpu`:

```bash
cd /root
unzip /path/to/kobalt-sigma-llama-gpu-bundle.zip -d /opt
cd /opt/kobalt-sigma-llama-gpu-bundle

bash bin/00-preflight.sh
bash bin/10-install-ollama-manual.sh
bash bin/11-configure-ollama-service.sh
```

Then, if you have a local GGUF model file:

```bash
bash bin/12-create-ollama-model-from-gguf.sh \
  /srv/ollama/models/aletheia-3.2-3b-uncensored.Q4_K_M.gguf \
  aletheia-3.2-3b
```

If the Kobalt app tree already exists:

```bash
cp env/kobalt-sigma.env.example /path/to/kobalt/.env
bash bin/30-deploy-kobalt-sigma.sh /path/to/kobalt
```

## Optional modes

- `bin/20-install-llama-cpp-native.sh` for native llama.cpp build
- `docker/compose.llama-cpp-server-cuda.yml` for Docker llama.cpp server
- `docker/compose.ollama.yml` for Docker Ollama instead of native Ollama

## Notes

- The Linux Containers tutorial recommends listening on `0.0.0.0` for container-host or LAN access, and either using the container IP directly or a LXD proxy device depending on exposure needs.
- Ollama’s official Linux docs support both the install script and the manual tarball install.
- The Aletheia repositories position the model as a research artifact and research-only deployment should stay in controlled environments.
