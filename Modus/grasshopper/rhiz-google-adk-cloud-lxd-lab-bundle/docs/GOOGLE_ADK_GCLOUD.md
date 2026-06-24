# Google ADK + Google Cloud SDK Notes

Install inside the VM:

```bash
bash /opt/rhiz-adk/scripts/11_install_gcloud_cli_ubuntu.sh
gcloud init
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

Install Python agent package inside the gateway venv:

```bash
cd /opt/rhiz-adk
. .venv/bin/activate
pip install -U google-adk
```

The scaffold deliberately keeps Google ADK as an optional provider. This prevents the whole local lab from failing when cloud credentials are absent.
