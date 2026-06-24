# Known limitations for the gaming lane

- GPU passthrough ties the gaming VM to the host that physically owns the GPU.
- Ceph makes the disk mobile and snapshot-friendly, but not the GPU itself.
- Live migration is generally not the first assumption for a gaming VM with passed-through PCIe GPU.
- The bundle does not ship Windows ISO images, virtio ISO images, GPU drivers, or Xbox SDK/GDK assets.
- The bundle does not transform a private cluster into Microsoft's Xbox Cloud Gaming backend.
