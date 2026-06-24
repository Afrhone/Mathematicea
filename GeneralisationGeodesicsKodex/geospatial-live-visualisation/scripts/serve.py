#!/usr/bin/env python3
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import sys, os

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080

class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".js": "text/javascript",
        ".mjs": "text/javascript",
        ".json": "application/json",
        ".ndjson": "application/x-ndjson",
        ".wasm": "application/wasm",
    }

print(f"Serving geospatial-live-visualisation at http://127.0.0.1:{port}/")
ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
