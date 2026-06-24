#!/usr/bin/env python3
import json, sys
from pathlib import Path

def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)

if len(sys.argv) < 2:
    die("Usage: validate.py <jsonfile>")

p = Path(sys.argv[1])
data = json.loads(p.read_text(encoding="utf-8"))

if isinstance(data, dict) and "elements" in data and isinstance(data["elements"], list):
    req = {"number","symbol","name"}
    if not all(req.issubset(e.keys()) for e in data["elements"][:10]):
        die("Advanced pack detected but missing required keys in first entries.")
    print("OK: Advanced element list pack.")
elif isinstance(data, dict) and "elements" in data and isinstance(data["elements"], dict):
    print("OK: Isotope pack.")
else:
    die("Unknown pack shape. Expected {elements:[...]} or {elements:{...}}.")
