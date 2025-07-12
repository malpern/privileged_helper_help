#!/bin/bash
# Build and sign script for SMAppService privileged helper POC
# This script creates the complete app bundle with proper code signing
# 
# IMPORTANT: Update DEVELOPER_ID and TEAM_ID with your own values below!
#
# To find your values:
# 1. List certificates: security find-identity -v -p codesigning
# 2. Look for "Developer ID Application: Your Name (TEAMID)"
# 3. Update the variables below

set -e

echo "Building and Signing Privileged Helper POC..."

# TODO: UPDATE THESE WITH YOUR OWN VALUES!
DEVELOPER_ID="Developer ID Application: [YOUR_NAME] ([YOUR_TEAM_ID])"
TEAM_ID="[YOUR_TEAM_ID]"

# Check if user updated the placeholder values
if [[ "$DEVELOPER_ID" == *"[YOUR_NAME]"* ]] || [[ "$TEAM_ID" == *"[YOUR_TEAM_ID]"* ]]; then
    echo "❌ ERROR: Please update DEVELOPER_ID and TEAM_ID with your own values!"
    echo ""
    echo "To find your values, run:"
    echo "  security find-identity -v -p codesigning"
    echo ""
    echo "Look for 'Developer ID Application: Your Name (TEAMID)'"
    echo "Then update the variables at the top of this script."
    exit 1
fi

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

# Create Info.plist with correct team ID
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
    <string>13.0</string>
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

echo "Signing executables..."

# Sign the helper daemon first (must be signed before the app)
codesign --force --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCDaemon.entitlements \
    --options runtime \
    --identifier "com.keypath.helperpoc" \
    "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

# Sign the main app
codesign --force --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCApp.entitlements \
    --options runtime \
    "${MACOS_PATH}/${APP_NAME}"

# Sign the entire app bundle
codesign --force --sign "${DEVELOPER_ID}" \
    --entitlements HelperPOCApp.entitlements \
    --options runtime \
    "${BUNDLE_PATH}"

echo "Verifying signatures..."
codesign --verify --verbose "${BUNDLE_PATH}"
codesign --verify --verbose "${LAUNCH_DAEMONS_PATH}/HelperPOCDaemon"

echo ""
echo "✅ Build and signing completed successfully!"
echo "App bundle: ${BUNDLE_PATH}"
echo ""
echo "Next steps:"
echo "1. Launch app: open ${BUNDLE_PATH}"
echo "2. Click 'Register Helper' - system will prompt for approval"
echo "3. Approve in System Settings > General > Login Items"
echo "4. Click 'Test Helper' to verify privileged operations"
echo ""
echo "Monitor logs:"
echo "  tail -f /tmp/helperpoc-app.log"
echo "  tail -f /tmp/helperpoc-daemon.log"