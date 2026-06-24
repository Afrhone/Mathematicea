#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/xcode/NanoSpectroLab/NanoSpectroLab"
mkdir -p "$APP/WebAssets"
rsync -a --delete "$ROOT/assets/html-animation/" "$APP/WebAssets/"
cat > "$APP/LocalContentView.swift" <<'SWIFT'
import SwiftUI
import WebKit

struct LocalContentView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        return WKWebView(frame: .zero, configuration: cfg)
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebAssets") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
}
SWIFT
echo "Exported HTML assets into $APP/WebAssets"
echo "If you use XcodeGen: cd xcode/NanoSpectroLab && xcodegen generate"
