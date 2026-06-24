# Fedora 43 LXD Cluster LimeSDR-USB Passthrough Bundle

Automation for a Fedora 43 host / LXD cluster to run a LimeSDR-USB lab container.

Default plan:

- Target node: `factau-rhiz`
- Target hint IP: `192.168.0.4`
- Container: `limesdr-usb-lab`
- Image: `ubuntu:25.04`
- Storage: `rhiz-storage`
- Profile: `limesdr-usb-plucky`
- Device: LimeSDR-USB via LXD `usb` passthrough
- Service: FastAPI spectrogram/probe API on port `8096`

## Run

```bash
unzip fedora43-lxd-limesdr-usb-cluster-bundle.zip
cd fedora43-lxd-limesdr-usb-cluster-bundle

cp .env.example .env
nano .env

bash scripts/00_doctor.sh
sudo bash scripts/01_host_fedora43_prereqs.sh
bash scripts/02_create_lxd_profile.sh
bash scripts/03_create_limesdr_container.sh
bash scripts/04_attach_limesdr_usb.sh
bash scripts/05_install_limesuite_in_container.sh
bash scripts/06_install_limesdr_api_service.sh
bash scripts/07_test_limesdr.sh
```

## Open

```text
http://<container-ip>:8096/health
http://<container-ip>:8096/probe
http://<container-ip>:8096/spectrogram.png
```

## Radio safety

The API and scripts do not transmit by default. Any RF transmission must comply with your local regulations.
