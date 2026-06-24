# RHIZ OpenADE LXD Agent Swarm Lab Bundle

A complete local-first development/data-science lab bundle to run **BearlyAI OpenADE** inside a sandboxed RHIZ LXD VM/container architecture.

## Features

- LXD VM bootstrap with local profile and Ceph `rhiz-storage`
- primary OpenADE instance and second contribution/fork instance
- Electron/EVM toolchain lane
- Docker Compose and Docker Swarm deployment profiles
- MCP server for LXD, Docker, Git, snapshots, RAG, GPU pool routing
- OpenAI-compatible agent gateway API
- KV-cache/RAG worker with MongoDB + Redis
- GPU pool routing for `llama-gpu` AMD/Vulkan and `gpu-compute` NVIDIA/CUDA
- VM snapshots, failover clone, rollback, and service recovery helpers
- CLI helpers for vibe coding tasks and agent orchestration

## Quick start on a LXD host

```bash
unzip rhiz-openade-lxd-agent-swarm-bundle.zip
cd rhiz-openade-lxd-agent-swarm-bundle

cp env/rhiz-openade.env.example env/rhiz-openade.env
nano env/rhiz-openade.env

bash scripts/00_doctor.sh
bash scripts/10_create_lxd_profile.sh
bash scripts/20_create_openade_vm.sh
bash scripts/21_snapshot_vm.sh baseline
bash scripts/30_bootstrap_vm.sh
bash scripts/40_deploy_stack.sh
bash scripts/50_test_gateway.sh
```

## VM services

- Agent Gateway: `:8091`
- MCP Server: `:8092`
- Lab API: `:8093`
- Dashboard UI: `:8094`

## Safety

OpenADE runs code agents. Keep it sandboxed in the VM, use git worktrees, and snapshot before major changes.
