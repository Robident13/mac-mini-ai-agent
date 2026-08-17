#!/bin/bash
# Builds FaceWidget.app — a transparent, always-on-top desktop widget
# showing the local model's face state.
set -euo pipefail

cd "$(dirname "$0")"
APP="$HOME/Applications/FaceWidget.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -swift-version 5 -O main.swift -o "$APP/Contents/MacOS/FaceWidget"
cp Resources/face.html "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>FaceWidget</string>
	<key>CFBundleDisplayName</key>
	<string>Local LLM Face</string>
	<key>CFBundleIdentifier</key>
	<string>local.llm.facewidget</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleExecutable</key>
	<string>FaceWidget</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
</dict>
PLIST
echo '</plist>' >> "$APP/Contents/Info.plist"

echo "Built: $APP"
