#!/bin/bash
# Build with ad-hoc signing for testing SMAppService on macOS 15.5
# Ad-hoc signing uses "-" as the identity

set -e

echo "Building with ad-hoc signing..."

# Build the Swift package
swift build -c release

# Create the app bundle structure
APP_NAME="HelperPOCApp"
BUNDLE_PATH="build/${APP_NAME}.app"
CONTENTS_PATH="${BUNDLE_PATH}/Contents"
MACOS_PATH="${CONTENTS_PATH}/MacOS"
LAUNCH_DAEMONS_PATH="${CONTENTS_PATH}/Library/LaunchDaemons"

# Clean and create directories
rm -rf build
mkdir -p "${MACOS_PATH}"
mkdir -p "${LAUNCH_DAEMONS_PATH}"

# Copy executables
cp ".build/release/HelperPOCApp" "${MACOS_PATH}/${APP_NAME}"
cp ".build/release/HelperPOCDaemon" "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

# Copy the plist
cp "com.keypath.helperpoc.plist" "${LAUNCH_DAEMONS_PATH}/"

# Create Info.plist
cat > "${CONTENTS_PATH}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.keypath.helperpoc</string>
    <key>CFBundleName</key>
    <string>Helper POC App</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SMPrivilegedExecutables</key>
    <dict>
        <key>com.keypath.helperpoc</key>
        <string>identifier "com.keypath.helperpoc"</string>
    </dict>
</dict>
</plist>
EOF

echo "Ad-hoc signing executables..."

# Ad-hoc sign the helper daemon first
codesign --force --sign "-" \
    --entitlements HelperPOCDaemon.entitlements \
    --identifier "com.keypath.helperpoc" \
    "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

# Ad-hoc sign the main app
codesign --force --sign "-" \
    --entitlements HelperPOCApp.entitlements \
    "${MACOS_PATH}/${APP_NAME}"

# Ad-hoc sign the entire app bundle
codesign --force --sign "-" \
    --entitlements HelperPOCApp.entitlements \
    "${BUNDLE_PATH}"

echo "Verifying signatures..."
codesign --verify --verbose "${BUNDLE_PATH}"
codesign --verify --verbose "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

echo ""
echo "✅ Ad-hoc build completed!"
echo "App bundle: ${BUNDLE_PATH}"
echo ""
echo "⚠️  IMPORTANT: Ad-hoc signed apps require special steps to open:"
echo "1. In Finder, navigate to: build/"
echo "2. Right-click (or Control-click) on ${APP_NAME}.app"
echo "3. Select 'Open' from the context menu"
echo "4. Click 'Open' in the security dialog"
echo ""
echo "After first launch, monitor logs:"
echo "  tail -f /tmp/helperpoc-app.log"
echo "  tail -f /tmp/helperpoc-daemon.log"