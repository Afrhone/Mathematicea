#!/usr/bin/env bash
set -Eeuo pipefail
# Run inside Ubuntu VM or Ubuntu container.
sudo apt update
sudo apt install -y apt-transport-https ca-certificates gnupg curl
sudo install -m 0755 -d /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
sudo apt update
sudo apt install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin
cat <<'EOF'
Next:
  gcloud init
  gcloud auth application-default login
  gcloud config set project <PROJECT_ID>
EOF
