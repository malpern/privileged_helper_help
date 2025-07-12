# Quick Setup Guide

This guide helps you get the SMAppService helper POC running on your system.

## Prerequisites

1. **macOS 15.x** (Sequoia recommended - macOS 16 beta has known issues)
2. **Apple Developer Program** membership ($99/year)
3. **Developer ID Certificate** (for proper signing)
4. **Xcode or Command Line Tools** installed

## Setup Steps

### 1. Clone and Build

```bash
git clone https://github.com/malpern/privileged_helper_help.git
cd privileged_helper_help
```

### 2. Test Basic Build

```bash
# This should work without any setup
swift build -c release
```

### 3. Update Code Signing (Required for SMAppService)

Find your Developer ID certificate:
```bash
security find-identity -v -p codesigning
```

Look for a line like:
```
"Developer ID Application: Your Name (ABC123XYZ)"
```

Edit `build_and_sign.sh` and update these lines:
```bash
DEVELOPER_ID="Developer ID Application: Your Name (ABC123XYZ)"
TEAM_ID="ABC123XYZ"
```

### 4. Create Developer ID Certificate (if needed)

If you don't have a Developer ID certificate:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/certificates)
2. Create new certificate → "Developer ID Application"
3. Download and install the certificate

### 5. Build Signed Version

```bash
./build_and_sign.sh
```

### 6. Test in Xcode (Recommended)

For the best debugging experience:
```bash
open Package.swift  # Opens in Xcode
```

Then:
1. Select "HelperPOCApp" scheme
2. Ensure "My Mac" is selected as destination
3. Press Cmd+R to run

## Expected Results

### ✅ On macOS 15.5 Sequoia
- App should build and run
- You'll get error `-67028` when registering helper
- This is the known issue we need help solving!

### ❌ On macOS 16 Beta  
- Complete SMAppService failure
- "Unable to read plist" errors
- Appears to be an OS beta bug

## Getting Help

If you encounter issues:

1. **Check the logs**: `tail -f /tmp/helperpoc-app.log`
2. **Verify signatures**: `codesign -dv build/HelperPOCApp.app`
3. **Open an issue** with your error messages and macOS version

## Next Steps

Once you have it running:
1. Try clicking "Register Helper" 
2. Note any different error messages
3. Share your findings in the GitHub issues

The goal is to solve the `-67028` error on macOS 15.x!