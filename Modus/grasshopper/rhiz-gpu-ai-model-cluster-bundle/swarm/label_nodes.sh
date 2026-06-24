#!/usr/bin/env bash
set -euo pipefail
docker node update --label-add rhiz.role=model-primary llama-gpu || true
docker node update --label-add rhiz.role=mcp-compute gpu-compute || true
docker node update --label-add rhiz.role=legacy-gpu sigmo-rhiz || true
docker node ls
