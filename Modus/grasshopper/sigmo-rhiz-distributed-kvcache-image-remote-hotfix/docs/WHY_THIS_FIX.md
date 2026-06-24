# Why Graph RAG failed

The LXD command tried to resolve `ubuntu:24.04` as if it were an image fingerprint/name in the wrong context. In this bundle, use the simplestreams remote alias:

```bash
LXD_IMAGE="images:ubuntu/24.04"
```

Then rerun Graph RAG creation. This hotfix also replaces stale literal `ubuntu:24.04` values in shell scripts.
