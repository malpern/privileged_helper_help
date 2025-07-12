#!/bin/bash

# Build and notarize helperpoc app for SMAppService testing
# This script builds with Developer ID certificate and full notarization

set -e

# Configuration
DEVELOPER_ID="Developer ID Application: Micah Alpern (X2RKZ5TG99)"
APP_BUNDLE_ID="com.keypath.helperpoc"
HELPER_BUNDLE_ID="com.keypath.helperpoc"
KEYCHAIN_PROFILE="notarytool-password"  # You'll need to set this up

# Paths
# Get the directory where the script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_DIR="$SCRIPT_DIR/helperpoc"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/helperpoc.app"

echo "🚀 Building helperpoc with Developer ID certificate and notarization..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cd "$PROJECT_DIR"
rm -rf "$BUILD_DIR"
xcodebuild clean -project helperpoc.xcodeproj

# Build with Developer ID certificate
echo "🔨 Building with Developer ID certificate..."
xcodebuild -project helperpoc.xcodeproj \
    -scheme helperpoc \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=X2RKZ5TG99 \
    PROVISIONING_PROFILE_SPECIFIER="" \
    build

# Copy app bundle to build directory
echo "📦 Copying app bundle..."
mkdir -p "$BUILD_DIR"
cp -R "$BUILD_DIR/DerivedData/Build/Products/Release/helperpoc.app" "$APP_PATH"

# Verify code signing
echo "✅ Verifying code signing..."
codesign -vvv --deep --strict "$APP_PATH"

# Create ZIP for notarization
echo "📦 Creating ZIP for notarization..."
ZIP_PATH="$BUILD_DIR/helperpoc.zip"
cd "$BUILD_DIR"
ditto -c -k --keepParent helperpoc.app helperpoc.zip

# Submit for notarization
echo "🚀 Submitting for notarization..."
echo "You need to run this command manually with your Apple ID:"
echo ""
echo "xcrun notarytool submit \"$ZIP_PATH\" \\"
echo "    --keychain-profile \"$KEYCHAIN_PROFILE\" \\"
echo "    --wait"
echo ""
echo "If you haven't set up the keychain profile yet, run:"
echo "xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
echo "    --apple-id \"your-apple-id@example.com\" \\"
echo "    --team-id \"X2RKZ5TG99\""
echo ""
echo "Then staple the notarization ticket:"
echo "xcrun stapler staple \"$APP_PATH\""
echo ""
echo "✅ Build complete! App bundle ready at: $APP_PATH"