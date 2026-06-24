# sigmo-rhiz distributed KV/RAG image remote hotfix

Copy this hotfix directory into the root of `sigmo-rhiz-distributed-kvcache-gnn-rag-gpu-bundle` or unzip it next to/over the bundle, then run from the bundle root:

```bash
cp env/cluster.env .env   # only if you do not already have .env
# keep your existing settings, but ensure:
grep '^LXD_IMAGE=' .env || echo 'LXD_IMAGE="images:ubuntu/24.04"' >> .env
bash health/check_image_remote.sh
bash scripts/21_fix_lxd_image_remote_and_graph_rag.sh
```

The patch normalizes `LXD_IMAGE` to `images:ubuntu/24.04`, patches old script literals, verifies the image can be resolved, then reruns `scripts/20_create_graph_rag.sh`.
