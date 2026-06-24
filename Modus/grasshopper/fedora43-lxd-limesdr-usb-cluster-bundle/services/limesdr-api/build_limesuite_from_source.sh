#!/usr/bin/env bash
set -Eeuo pipefail
apt-get update
apt-get install -y git g++ cmake libsqlite3-dev libi2c-dev libusb-1.0-0-dev freeglut3-dev
cd /opt
rm -rf LimeSuite
git clone https://github.com/myriadrf/LimeSuite.git
cd LimeSuite
mkdir -p build
cd build
cmake ..
make -j"$(nproc)"
make install
ldconfig
cd ../udev-rules
bash install.sh
udevadm control --reload-rules || true
udevadm trigger || true
