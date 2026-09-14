#!/bin/bash
# Builds a release binary and wraps it in a double-clickable DELESSHION.app
# bundle in the project root. Run this after making changes, then drag
# DELESSHION.app into /Applications (or let this script do it with --install).
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="DELESSHION"
BUNDLE_ID="com.sshrunner.delesshion"
APP_DIR="${APP_NAME}.app"

echo "Building release binary..."
swift build -c release

echo "Assembling ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string></string>
</dict>
</plist>
PLIST

echo "Ad-hoc signing..."
codesign --force --deep --sign - "${APP_DIR}"

echo "Built ${APP_DIR}"

if [[ "${1:-}" == "--install" ]]; then
    echo "Installing to /Applications..."
    rm -rf "/Applications/${APP_DIR}"
    cp -R "${APP_DIR}" /Applications/
    echo "Installed to /Applications/${APP_DIR}"
fi
