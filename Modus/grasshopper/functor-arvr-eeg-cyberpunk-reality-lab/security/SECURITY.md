# Security

## External ingress

Only gateway may touch external APIs.

```text
external → gateway → internal bus/sinks
```

## EEG

Treat EEG as sensitive bio-signal telemetry. Do not publish raw samples. Do not infer medical or consciousness status.

## AR/VR

Avoid unsafe locomotion defaults. Keep guardian/boundary systems active.

## Cluster

Never expose LXD socket to untrusted containers. Keep Ceph keys scoped and read-only.
