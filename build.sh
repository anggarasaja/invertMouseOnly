#!/bin/bash
# Builds invertMouseOnly.app from main.swift. No Xcode project needed.
set -euo pipefail
cd "$(dirname "$0")"

# Version: VERSION env var wins, else the newest git tag, else 1.0.0.
VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo 1.0.0)}"
VERSION="${VERSION#v}"

APP="invertMouseOnly.app"
BIN="$APP/Contents/MacOS/invertMouseOnly"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# App icon (built asset committed in icon/).
if [ -f icon/invertMouseOnly.icns ]; then
  cp icon/invertMouseOnly.icns "$APP/Contents/Resources/"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>invertMouseOnly</string>
    <key>CFBundleDisplayName</key>       <string>Invert Mouse Only</string>
    <key>CFBundleIdentifier</key>        <string>local.invertmouseonly</string>
    <key>CFBundleExecutable</key>        <string>invertMouseOnly</string>
    <key>CFBundleIconFile</key>          <string>invertMouseOnly</string>
    <key>CFBundleVersion</key>           <string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <!-- Menu bar only: no Dock icon, no app switcher entry. -->
    <key>LSUIElement</key>               <true/>
</dict>
</plist>
PLIST

swiftc -O -target "$(uname -m)-apple-macos13.0" main.swift -o "$BIN"

# Ad-hoc sign so macOS treats it as a stable app identity for the
# Accessibility grant. Rebuilding changes the hash, so the permission has to be
# re-granted after a rebuild (toggle it off and on in System Settings).
codesign --force --sign - "$APP"

echo "Built $(pwd)/$APP"
