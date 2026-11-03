#!/usr/bin/env bash
# Builds "Figma Bridge Setup.app" and zips it. Runs on macOS (GitHub Actions).
set -euo pipefail

cd "$(dirname "$0")/.."
APP="dist/Figma Bridge Setup.app"

rm -rf dist && mkdir -p dist
osacompile -o "$APP" mac/launcher.applescript
cp install.sh "$APP/Contents/Resources/install.sh"

# Adding install.sh breaks osacompile's signature, and Apple Silicon won't open an
# unsigned app at all, so sign it again (ad hoc: free, but not Apple-verified).
codesign --force --deep --sign - "$APP"

# ditto keeps the permissions and signature that a plain zip would lose.
ditto -c -k --keepParent "$APP" dist/FigmaBridgeSetup-mac.zip
