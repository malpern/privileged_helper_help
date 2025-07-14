# macOS SMAppService Privileged Helper Implementation Guide

A complete guide for implementing privileged helper daemons using Apple's modern SMAppService API on macOS 15+. This repository provides a working example and step-by-step instructions to avoid common configuration pitfalls.

**Reference implementation for keyboard remapping and system-level operations**

## Overview

This guide helps you implement a privileged helper daemon that can:
1. **Register with SMAppService** - Use Apple's modern service management API
2. **Execute privileged operations** - Run tasks requiring root permissions
3. **Communicate via XPC** - Secure inter-process communication
4. **Work on macOS 15+** - Compatible with Sequoia and later

## 🎯 Common Issues Resolved

### Error 108 "Unable to read plist"
This error typically occurs when mixing legacy SMJobBless configuration with modern SMAppService:

**Root Causes:**
1. **Mixed APIs**: Using `SMAuthorizedClients`/`SMPrivilegedExecutables` (SMJobBless) with SMAppService
2. **Missing .plist extension**: `daemon(plistName:)` requires the full filename including extension

**Solutions:** See [Configuration Guide](#-correct-configuration) below.

## 📚 Essential Documentation

### Apple's Official Resources
- [Updating helper executables from earlier versions of macOS](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- [Service Management Framework](https://developer.apple.com/documentation/servicemanagement)

### LLM-Accessible Documentation
This repository includes `servicemanagement-updating-helper-executables-from-earlier-versions-of-macos.md` - a markdown version of Apple's documentation generated using [llm.codes](https://steipete.me/posts/2025/llm-codes-transform-developer-docs) by [@steipete](https://x.com/steipete).

**Why this matters:** Apple's documentation requires JavaScript, making it difficult for LLMs to parse. The markdown version enables AI assistants to provide accurate guidance based on official Apple documentation.

**Generate your own:** Use [@steipete's llm.codes tool](https://steipete.me/posts/2025/llm-codes-transform-developer-docs) to convert any Apple documentation into LLM-readable markdown format.

## ✅ Correct Configuration

### Main Application

**Info.plist** - No SMAppService-specific keys needed:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Standard app keys only - no SMPrivilegedExecutables -->
</dict>
</plist>
```

**Entitlements** (`helperpoc.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

**Swift Implementation**:
```swift
// CRITICAL: Include .plist extension
private let helperPlistName = "com.keypath.helperpoc.helper.plist"

let service = SMAppService.daemon(plistName: helperPlistName)
try service.register()
```

### Helper Daemon

**Info.plist** - Standard bundle keys only:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.keypath.helperpoc.helper</string>
    <key>CFBundleName</key>
    <string>helperpoc-helper</string>
    <!-- No SMAuthorizedClients with SMAppService -->
</dict>
</plist>
```

**Entitlements** (`helperpoc-helper.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.developer.service-management.managed-by-main-app</key>
<true/>
```

**Daemon Configuration** (`com.keypath.helperpoc.helper.plist`):
```xml
<dict>
    <key>Label</key>
    <string>com.keypath.helperpoc.helper</string>
    <key>BundleProgram</key>
    <string>Contents/MacOS/helperpoc-helper</string>
    <key>AssociatedBundleIdentifiers</key>
    <array>
        <string>com.keypath.helperpoc</string> <!-- Main app identifier -->
    </array>
    <key>MachServices</key>
    <dict>
        <key>com.keypath.helperpoc.xpc</key>
        <true/>
    </dict>
</dict>
```

## 🏗️ Required Bundle Structure

```
helperpoc.app/
├── Contents/
│   ├── MacOS/
│   │   ├── helperpoc           # Main app binary
│   │   └── helperpoc-helper    # Helper daemon binary
│   └── Library/
│       └── LaunchDaemons/
│           └── com.keypath.helperpoc.helper.plist
```

## 🧪 Step-by-Step Implementation

### 1. Prerequisites
- macOS 15.x Sequoia or later
- Xcode 16.x
- Apple Developer account with Developer ID certificates

### 2. Build and Test
```bash
# Clone repository
git clone https://github.com/malpern/privileged_helper_help.git
cd privileged_helper_help/helperpoc

# Build project
xcodebuild -project helperpoc.xcodeproj -scheme helperpoc -configuration Debug clean build

# Launch app
open build/Debug/helperpoc.app
```

### 3. Registration Process
1. **Click "Register Helper"** - May initially show "Operation not permitted"
2. **Approve in System Settings** - macOS will prompt for permission
3. **Verify "Helper Status: Enabled"** - Registration successful
4. **Test functionality** - Click "Test Helper" to verify privileged operations

### 4. Troubleshooting Checklist

**Error 108 "Unable to read plist":**
- ✅ Remove `SMAuthorizedClients` from helper's Info.plist
- ✅ Remove `SMPrivilegedExecutables` from main app's Info.plist  
- ✅ Add `.plist` extension to `daemon(plistName:)` parameter
- ✅ Verify `AssociatedBundleIdentifiers` references main app

**"Operation not permitted":**
- ✅ Normal first-time behavior - approve in System Settings
- ✅ Check System Settings > General > Login Items & Extensions

**Build failures:**
- ✅ Ensure helper binary is copied to correct bundle location
- ✅ Verify daemon plist is embedded in `Contents/Library/LaunchDaemons/`

## 📖 Key Differences: SMJobBless vs SMAppService

| Feature | SMJobBless (Legacy) | SMAppService (Modern) |
|---------|---------------------|----------------------|
| macOS Version | 10.6-13.0 | 13.0+ |
| Configuration | SMAuthorizedClients/SMPrivilegedExecutables | Bundle structure only |
| Helper Location | Contents/Library/LaunchServices | Contents/Library/LaunchDaemons |
| Plist Reference | Without extension | **With .plist extension** |
| Authorization | Manual code signing validation | Automatic with proper bundle |
| API Status | Deprecated | Current best practice |

## 🔧 Advanced Configuration

### XPC Communication
The helper implements a simple XPC protocol for secure communication:

```swift
@objc protocol HelperProtocol {
    func createTestFile(reply: @escaping (Bool, String?) -> Void)
}
```

### Logging and Debugging
- App logs: Check console for SMAppService registration messages
- Helper logs: Monitor system logs for daemon execution
- Bundle verification: Use `codesign -vvv` to verify signatures

### Production Deployment
1. **Code signing**: Use Developer ID Application certificates
2. **Notarization**: Required for distribution outside Mac App Store
3. **User approval**: Always required for first-time registration

## 🙏 Acknowledgments

- **Quinn "The Eskimo!"** @ Apple Developer Technical Support - For identifying the root causes in [this Apple Developer Forums thread](https://developer.apple.com/forums/thread/792826)
- **[@steipete](https://x.com/steipete)** - For creating [llm.codes](https://steipete.me/posts/2025/llm-codes-transform-developer-docs) which enabled AI-assisted debugging with proper Apple documentation

## 🔗 Additional Resources

- [Apple Developer Forums Thread](https://developer.apple.com/forums/thread/792826) - Complete troubleshooting discussion
- [Kanata Keyboard Remapper](https://github.com/jtroo/kanata) - Target integration project
- [llm.codes Documentation Tool](https://steipete.me/posts/2025/llm-codes-transform-developer-docs) - Convert Apple docs for AI assistance

---

*This guide demonstrates working SMAppService implementation on macOS 15. For questions or issues, refer to Apple's official documentation or the developer forums.*