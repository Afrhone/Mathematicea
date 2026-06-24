#!/usr/bin/env python3
import hashlib, json, secrets, time
seed = f"YETTI-715|phiiiiv3i4|{time.time()}|{secrets.token_hex(16)}"
print(json.dumps({"seed": seed, "sha256": hashlib.sha256(seed.encode()).hexdigest()}, indent=2))
