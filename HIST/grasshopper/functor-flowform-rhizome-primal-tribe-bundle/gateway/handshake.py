#!/usr/bin/env python3
import argparse, json, os, secrets, time, hashlib
from pathlib import Path

DEFAULT_PHRASE = "YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof."

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--token-file", default=os.getenv("GATEWAY_TOKEN_FILE", "/etc/rhizome/gateway.token"))
    ap.add_argument("--out", default="/tmp/rhizome-handshake.json")
    ap.add_argument("--node", default=os.getenv("NODE_NAME", "unknown"))
    ap.add_argument("--namespace", default=os.getenv("NAMESPACE", "factory-rhizome-lab-studio"))
    args = ap.parse_args()

    token_path = Path(args.token_file)
    token_path.parent.mkdir(parents=True, exist_ok=True)
    if not token_path.exists():
        token = secrets.token_urlsafe(32)
        token_path.write_text(token + "\n")
        token_path.chmod(0o600)
    else:
        token = token_path.read_text().strip()

    phrase = os.getenv("HANDSHAKE_PHRASE", DEFAULT_PHRASE)
    obj = {
        "namespace": args.namespace,
        "node": args.node,
        "badge": "YETI-715",
        "phrase_sha256": hashlib.sha256(phrase.encode()).hexdigest(),
        "token_preview": token[:8] + "...",
        "created_at": time.time(),
        "one_time_config": {
            "header": "Authorization: Bearer ${GATEWAY_TOKEN}",
            "outpost_url": os.getenv("OUTPOST_URL", "http://127.0.0.1:7150"),
        }
    }
    Path(args.out).write_text(json.dumps(obj, indent=2))
    print(json.dumps(obj, indent=2))

if __name__ == "__main__":
    main()
