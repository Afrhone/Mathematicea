#!/usr/bin/env python3
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import os

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
print('Prime Radi Tourbillon standalone server')
print('Open http://127.0.0.1:8080/standalone.html')
ThreadingHTTPServer(('127.0.0.1', 8080), SimpleHTTPRequestHandler).serve_forever()
