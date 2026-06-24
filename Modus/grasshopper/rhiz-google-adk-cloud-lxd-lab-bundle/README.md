# RHIZ Google ADK + Cloud SDK + LXD Heavy Compute Lab Bundle

This bundle creates a **development data-science lab VM** inside the RHIZ/LXD cluster and deploys an **agent gateway API** that can route between:

- local OpenAI-compatible inference endpoints such as `llama-gpu:8089/v1` or `gpu-compute:8080/v1`
- local Ollama-compatible endpoints such as `llama-gpu:11435`
- Google ADK agents, when `google-adk` and Google credentials are configured
- Google Cloud SDK workflows for cloud inference, artifact storage, and remote compute operations

It is built around the RHIZ product split described in the PRD: control plane, directive plane, analysis plane, awareness plane, host plane, compute plane, and storage plane. The scripts keep destructive actions behind explicit flags and snapshots.

## Quick start

```bash
unzip rhiz-google-adk-cloud-lxd-lab-bundle.zip
cd rhiz-google-adk-cloud-lxd-lab-bundle
cp env/rhiz-adk-lab.env.example env/rhiz-adk-lab.env
nano env/rhiz-adk-lab.env

bash scripts/00_doctor.sh
bash scripts/10_install_local_tools.sh
bash scripts/20_create_lxd_profile.sh
bash scripts/30_create_compute_vm.sh
bash scripts/31_snapshot_compute_vm.sh
bash scripts/40_bootstrap_vm_lab.sh
bash scripts/50_deploy_agent_gateway.sh
bash scripts/60_test_gateway.sh
```

## Default topology

```text
operator host / LXD controller
  ├─ creates Ubuntu VM: rhiz-adk-lab
  ├─ attaches local profile: rhiz-adk-lab-profile
  ├─ snapshots after bootstrap
  └─ deploys agent gateway stack inside the VM

rhiz-adk-lab VM
  ├─ Docker Compose stack
  ├─ FastAPI OpenAI-compatible gateway
  ├─ ADK agent scaffold
  ├─ MCP-style cluster tools
  ├─ model route registry
  └─ optional Google Cloud SDK integration

local model nodes
  ├─ llama-gpu AMD Vulkan model server, e.g. http://192.168.0.125:8089/v1
  ├─ llama-gpu proxy/Ollama style, e.g. http://192.168.0.125:11435
  └─ gpu-compute NVIDIA CUDA model server, e.g. http://192.168.0.52:8080/v1
```

## What gets generated

- LXD VM profile with CPU, memory, disk, bridged LAN, cloud-init, and failover metadata
- VM bootstrap script for Ubuntu 24.04/25.04 lab use
- Docker Compose stack for agent gateway, Redis, MongoDB, telemetry, and optional OpenWebUI bridge
- FastAPI agent gateway with OpenAI-compatible `/v1/chat/completions` and `/v1/models`
- Google ADK scaffold with graceful fallback if ADK credentials are not configured
- Google Cloud SDK installer and init helper
- model/agent pool registry with local-first provider routing
- snapshot, restore, export, and failover helpers
- swarm labeling and routing helpers
- imported bundle placeholders under `vendor/imported-bundles/`

## Safety gates

Scripts that mutate infrastructure are designed to be explicit. VM delete/recreate requires `RHIZ_CONFIRM_DESTROY=YES`. Promotion/failover scripts write plans first and ask for confirmation unless `RHIZ_ASSUME_YES=1`.
