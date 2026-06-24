#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

if ! is_yes "${GOOGLE_CLOUD_ENABLE:-yes}"; then
  log "GOOGLE_CLOUD_ENABLE=no; skipping"
  exit 0
fi

tmp_remote="$(generated_file vm-gcloud-remote.sh)"
cat > "$tmp_remote" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
sudo install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d /opt/google
if [[ ! -f /usr/share/keyrings/cloud.google.gpg ]]; then
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
fi
cat <<APT | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main
APT
sudo apt-get update
sudo apt-get install -y google-cloud-cli
if [[ -n '${GOOGLE_CLOUD_PROJECT}' ]]; then
  gcloud config set project '${GOOGLE_CLOUD_PROJECT}' || true
fi
if [[ -n '${GOOGLE_APPLICATION_CREDENTIALS_B64:-}' ]]; then
  echo '${GOOGLE_APPLICATION_CREDENTIALS_B64}' | base64 -d | sudo tee '${GOOGLE_APPLICATION_CREDENTIALS}' >/dev/null
  sudo chmod 600 '${GOOGLE_APPLICATION_CREDENTIALS}'
fi
cat | sudo tee /etc/profile.d/google-cloud-colab.sh >/dev/null <<PROFILE
export GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
export GOOGLE_CLOUD_REGION=${GOOGLE_CLOUD_REGION}
export GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}
PROFILE
EOF
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-gcloud-remote.sh"
vm_exec "bash /tmp/vm-gcloud-remote.sh"
log "VM Google Cloud CLI configured"
