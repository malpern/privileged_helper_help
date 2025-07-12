#!/bin/bash
# Test build script without code signing
# This creates an unsigned app bundle for testing on macOS 15.5

set -e

echo "Building test app bundle (unsigned)..."

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

echo ""
echo "✅ Test build completed!"
echo "App bundle: ${BUNDLE_PATH}"
echo ""
echo "⚠️  Note: This is an UNSIGNED build for testing only."
echo "SMAppService requires proper code signing to work."
echo ""
echo "To test: open ${BUNDLE_PATH}"