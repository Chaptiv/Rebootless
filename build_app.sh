#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🔨 Building Rebootless in release mode..."
swift build -c release

APP_NAME="Rebootless.app"
CONTENTS="$APP_NAME/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "📦 Assembling $APP_NAME bundle..."
rm -rf "$APP_NAME"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
cp ".build/release/Rebootless" "$MACOS/Rebootless"
chmod +x "$MACOS/Rebootless"

# Copy Icon
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

# Create Info.plist
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Rebootless</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.chaptiv.rebootless</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Rebootless</string>
    <key>CFBundleDisplayName</key>
    <string>Rebootless</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Rebootless requires permission to execute administrator commands when restarting system services like Core Audio or Bluetooth.</string>
</dict>
</plist>
EOF

# Sign the app bundle with ad-hoc signature
echo "🔏 Signing $APP_NAME..."
codesign --force --deep --sign - "$APP_NAME"

echo "✅ Successfully built $APP_NAME!"
echo ""
echo "To run Rebootless now:"
echo "  open $APP_NAME"
echo ""
echo "To install to /Applications:"
echo "  cp -R $APP_NAME /Applications/"
