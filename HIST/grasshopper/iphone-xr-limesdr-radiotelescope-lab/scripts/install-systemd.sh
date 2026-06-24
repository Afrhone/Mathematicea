#!/usr/bin/env bash
set -Eeuo pipefail
sudo mkdir -p /opt/iphone-xr-limesdr-radiotelescope-lab
sudo rsync -a --delete ./ /opt/iphone-xr-limesdr-radiotelescope-lab/
sudo cp systemd/iphone-limesdr-observatory.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now iphone-limesdr-observatory.service
