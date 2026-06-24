#!/usr/bin/env python3
import secrets, hashlib, json, time, os
token = secrets.token_urlsafe(32)
record = {
  "token": token,
  "sha256": hashlib.sha256(token.encode()).hexdigest(),
  "created_at": time.time(),
  "scope": os.getenv("TOKEN_SCOPE", "dev:octopuce")
}
print(json.dumps(record, indent=2))
