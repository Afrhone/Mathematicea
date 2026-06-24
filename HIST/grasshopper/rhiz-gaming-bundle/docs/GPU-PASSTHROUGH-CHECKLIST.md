# GPU passthrough checklist for the Windows gaming VM

- BIOS/UEFI virtualization extensions enabled
- IOMMU enabled in kernel args
- GPU and HDMI audio function bound to `vfio-pci`
- OVMF secure-boot firmware available
- `swtpm` installed for virtual TPM 2.0
- Ceph secret already defined in libvirt
- Windows ISO and virtio ISO present on the host
- Optional: isolate host CPUs used by the VM for better latency

## Notes

For a dual-function GPU, pass both the display and audio function.
If you want lower latency during install/troubleshooting, keep a fallback SPICE/virtio video device enabled initially.
