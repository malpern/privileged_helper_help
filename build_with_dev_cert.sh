#!/bin/bash
# Build with your Apple Development certificate for testing SMAppService
# This attempts to work around Xcode's automatic signing limitations

set -e

echo "Building with your Apple Development certificate..."

# Your certificate from earlier
DEVELOPER_ID="Apple Development: Micah Alpern (3YFH89N33S)"
TEAM_ID="X2RKZ5TG99"

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

# Create Info.plist with Apple Development certificate requirements
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
        <string>identifier "com.keypath.helperpoc" and certificate leaf[subject.OU] = "${TEAM_ID}"</string>
    </dict>
</dict>
</plist>
EOF

echo "Signing with Apple Development certificate..."

# Sign the helper daemon with no hardened runtime for testing
codesign --force --deep --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCDaemon.entitlements \
    --identifier "com.keypath.helperpoc" \
    --timestamp=none \
    "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

# Sign the main app
codesign --force --deep --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCApp.entitlements \
    --timestamp=none \
    "${MACOS_PATH}/${APP_NAME}"

# Sign the entire app bundle
codesign --force --deep --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCApp.entitlements \
    --timestamp=none \
    "${BUNDLE_PATH}"

echo "Verifying signatures..."
codesign --verify --verbose "${BUNDLE_PATH}"
codesign --verify --verbose "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

echo ""
echo "✅ Build completed with Apple Development certificate!"
echo "App bundle: ${BUNDLE_PATH}"
echo ""
echo "To test: open ${BUNDLE_PATH}"
echo ""
echo "Note: This uses development signing. For production use,"
echo "you would need a Developer ID certificate."