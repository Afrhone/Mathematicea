#!/usr/bin/env python3
import os, pathlib, yaml
root = pathlib.Path(__file__).resolve().parents[1]
rendered = root/'rendered'
rendered.mkdir(exist_ok=True)
topo = yaml.safe_load((root/'config/topology.yaml').read_text())
(rendered/'firewalld-allowlist.sh').write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + "\n".join(
    f"sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address={ip} port protocol=tcp port={port} accept'"
    for ip in topo['allowed_clients'] for port in topo['ports'].values()
) + "\nsudo firewall-cmd --reload\n")
(rendered/'provider-summary.txt').write_text((root/'config/providers.yaml').read_text())
print('rendered firewalld and provider summary')
