# SDR Notes

Default mode is `synthetic`, which creates IQ-like test signals.

For RTL-SDR experiments:

- On Linux, pass `/dev/bus/usb` into Docker.
- On macOS Docker Desktop, USB SDR pass-through is limited. Run GNU Radio/rtl_sdr natively or on a Linux host and point the web app to that host.

Future extension hooks:

- `rtl_sdr -f <freq> -s <sample_rate> -g <gain> -` piping IQ into the Python service.
- SoapySDR or GNU Radio network stream.
- HackRF/Airspy through host-side capture process.
