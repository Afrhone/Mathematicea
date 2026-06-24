# LimeSDR server-side notes

Install host packages in the VM or on the hypervisor, depending on USB passthrough:

```bash
sudo apt update
sudo apt install -y soapysdr-tools soapysdr-module-lms7 limesuite limesuite-udev
SoapySDRUtil --find
SoapySDRUtil --probe="driver=lime"
```

For Docker access, the safest first pass is to run the SDR process on the VM host and expose IQ/spectrogram to the app. If you place USB in Docker, map `/dev/bus/usb` and add the required permissions.

Hydrogen line starting frequency:

```text
1420.405751 MHz
```

Use appropriate antennas/filters/LNAs for actual radio astronomy.
