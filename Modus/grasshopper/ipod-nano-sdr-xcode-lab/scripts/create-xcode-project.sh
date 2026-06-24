#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../xcode/NanoSpectroLab"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Install XcodeGen first: brew install xcodegen"
  echo "Or create a SwiftUI iOS App manually in Xcode and add NanoSpectroLab/*.swift + WebAssets."
  exit 2
fi
xcodegen generate
