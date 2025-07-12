#!/bin/bash
# Build and sign with Developer ID certificate for notarization
# This creates a properly signed app bundle ready for notarization

set -e

echo "Building with Developer ID certificate for notarization..."

# Your Developer ID certificate
DEVELOPER_ID="Developer ID Application: Micah Alpern (X2RKZ5TG99)"
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

# Create Info.plist with Developer ID requirements
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
        <string>identifier "com.keypath.helperpoc" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "${TEAM_ID}"</string>
    </dict>
</dict>
</plist>
EOF

echo "Signing with Developer ID certificate..."

# Sign the helper daemon first with hardened runtime
codesign --force --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCDaemon.entitlements \
    --options runtime \
    --identifier "com.keypath.helperpoc" \
    --timestamp \
    "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

# Sign the main app with hardened runtime
codesign --force --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCApp.entitlements \
    --options runtime \
    --timestamp \
    "${MACOS_PATH}/${APP_NAME}"

# Sign the entire app bundle with hardened runtime
codesign --force --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCApp.entitlements \
    --options runtime \
    --timestamp \
    "${BUNDLE_PATH}"

echo "Verifying signatures..."
codesign --verify --verbose "${BUNDLE_PATH}"
codesign --verify --verbose "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

# Check signature details
echo ""
echo "Signature details:"
codesign -dv "${BUNDLE_PATH}"

echo ""
echo "✅ Build completed with Developer ID certificate!"
echo "App bundle: ${BUNDLE_PATH}"
echo ""
echo "Ready for notarization!"