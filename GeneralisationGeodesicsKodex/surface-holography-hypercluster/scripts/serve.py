#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os

os.chdir(Path(__file__).resolve().parents[1])
port = int(os.environ.get('PORT', '8080'))
print(f"Serving Surface Holography Hypercluster on http://127.0.0.1:{port}/standalone.html")
ThreadingHTTPServer(('127.0.0.1', port), SimpleHTTPRequestHandler).serve_forever()
