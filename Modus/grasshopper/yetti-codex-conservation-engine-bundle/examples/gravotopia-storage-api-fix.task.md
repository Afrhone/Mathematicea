# Example Codex Task

## Goal

Fix Docker container startup failure:

```text
unable to start container process: error mounting volume to /srv/uploads:
mkdirat ... /srv/uploads: read-only file system
```

## Likely patch

Ensure `/srv/uploads` exists in the image before Docker mounts the volume, or mount to an existing writable path. If `read_only: true` is enabled, create the mountpoint at build time.

## Minimal Dockerfile patch

```dockerfile
RUN mkdir -p /srv/uploads
```

Add chown if service runs as a non-root user.
