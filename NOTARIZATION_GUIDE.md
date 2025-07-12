# SMAppService Notarization Guide

## Overview
This guide walks through the complete notarization workflow required for SMAppService on macOS 15. Our testing confirms that **full notarization is required** even for development testing.

## Prerequisites

### 1. Apple Developer Account
- Active Apple Developer Program membership
- Access to notarization service
- Developer ID Application certificate installed

### 2. Certificates Setup
Verify you have the required certificates:
```bash
# Check available certificates
security find-identity -p codesigning -v

# Should show something like:
# 1) ABC123... "Apple Development: Your Name (TEAMID)"  
# 2) DEF456... "Developer ID Application: Your Name (TEAMID)"
```

### 3. Apple ID Credentials
Set up notarytool credentials (one-time setup):
```bash
# Store Apple ID credentials securely
xcrun notarytool store-credentials "notarytool-password" \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password"
```

**Note**: Use an App-Specific Password, not your regular Apple ID password.

## Quick Start

### 1. Build with Developer ID
```bash
# Use the provided build script
cd /path/to/privileged_helper_help
./build_and_notarize.sh
```

### 2. Submit for Notarization
The script will provide commands like:
```bash
# Submit the ZIP file
xcrun notarytool submit "helperpoc/build/helperpoc.zip" \
    --keychain-profile "notarytool-password" \
    --wait

# If successful, staple the ticket
xcrun stapler staple "helperpoc/build/helperpoc.app"
```

### 3. Test SMAppService
```bash
# Launch the notarized app
open helperpoc/build/helperpoc.app

# Click "Register Helper" - should now work!
```

## Manual Process

If you prefer manual control:

### 1. Build with Xcode
```bash
cd helperpoc
xcodebuild -project helperpoc.xcodeproj \
    -scheme helperpoc \
    -configuration Release \
    CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
    build
```

### 2. Create ZIP for Notarization
```bash
# Create ZIP (required format for notarization)
cd build/DerivedData/Build/Products/Release
ditto -c -k --keepParent helperpoc.app helperpoc.zip
```

### 3. Submit and Wait
```bash
# Submit (this can take 5-15 minutes)
xcrun notarytool submit helperpoc.zip \
    --keychain-profile "notarytool-password" \
    --wait
```

### 4. Staple Ticket
```bash
# Attach notarization ticket to app
xcrun stapler staple helperpoc.app
```

### 5. Verify
```bash
# Verify notarization worked
xcrun stapler validate helperpoc.app
spctl -a -t exec -vv helperpoc.app
```

## Troubleshooting

### Common Issues

**"No keychain profile found"**
```bash
# Re-run credentials setup
xcrun notarytool store-credentials "notarytool-password" \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOUR_TEAM_ID"
```

**"Invalid credentials"**
- Use App-Specific Password, not regular password
- Verify Team ID matches your Developer account

**"Notarization failed"**
```bash
# Get detailed log
xcrun notarytool log SUBMISSION_ID \
    --keychain-profile "notarytool-password"
```

### Verification Commands
```bash
# Check code signing
codesign -vvv --deep --strict helperpoc.app

# Check notarization status  
xcrun stapler validate helperpoc.app

# Check Gatekeeper acceptance
spctl -a -t exec -vv helperpoc.app
```

## Expected Results

### ✅ Success Indicators
- `xcrun stapler validate` shows "The validate action worked!"
- `spctl -a -t exec` shows "accepted" with "source=Notarized Developer ID"
- SMAppService registration succeeds (no error 108)

### ❌ Failure Indicators  
- Error 108 "Unable to read plist" still occurs
- `spctl` shows "rejected" or "Unnotarized Developer ID"
- `stapler validate` fails

## Why This Works

SMAppService on macOS 15 requires the complete security chain:
1. **Developer ID certificate** (not just Development)
2. **Hardened runtime** enabled  
3. **Notarization** by Apple
4. **Stapled ticket** attached to app bundle

Our testing shows that **ALL four requirements** must be met for SMAppService to accept the helper daemon registration.

## Next Steps

Once notarization works:
1. ✅ Test helper registration (should succeed)
2. ✅ Test XPC communication with helper
3. ✅ Verify privileged operations work
4. ✅ Document the complete working solution

---

*This guide is based on extensive testing with macOS 15.5 Sequoia and Xcode 16.x*