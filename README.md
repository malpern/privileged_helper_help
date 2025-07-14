# macOS SMAppService Implementation - Solution Identified! 🔍

This repository demonstrates a complete **SMAppService implementation** that initially failed with Error 108 "Unable to read plist" on macOS 15 Sequoia. Through community help and Apple Developer Support, we've identified what appear to be the root causes.

**Promising Solution!** Thanks to Quinn "The Eskimo!" @ Developer Technical Support @ Apple for identifying critical configuration issues. 🙏

**Updated July 2025: Root causes identified, testing in progress**

## 🎯 The Identified Issues

After extensive debugging and [posting to Apple Developer Forums](https://developer.apple.com/forums/thread/792826), Quinn "The Eskimo!" identified two critical issues:

### 1. **Mixed SMJobBless and SMAppService APIs**
We were incorrectly using legacy SMJobBless configuration keys with the modern SMAppService API:
- ❌ `SMAuthorizedClients` in helper's Info.plist (SMJobBless only)
- ❌ `SMPrivilegedExecutables` in main app's Info.plist (SMJobBless only)
- ✅ **Solution**: Remove these keys entirely - they're not used by SMAppService

### 2. **Missing .plist Extension**
The `daemon(plistName:)` method requires the full filename including extension:
- ❌ `SMAppService.daemon(plistName: "com.keypath.helperpoc.helper")`
- ✅ `SMAppService.daemon(plistName: "com.keypath.helperpoc.helper.plist")`

## What We're Building

We're building an app that integrates with [Kanata](https://github.com/jtroo/kanata), a cross-platform keyboard remapper. Our macOS implementation requires:

1. **Register a privileged daemon** using the modern `SMAppService` API
2. **Execute root-level operations** for system-wide keyboard event interception  
3. **Communicate with the main app** via XPC
4. **Work reliably on macOS 15+** (Sequoia and later)

## 📚 Key Documentation

- **Apple's Official Guide**: [Updating helper executables from earlier versions of macOS](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- **Local Copy**: See `servicemanagement-updating-helper-executables-from-earlier-versions-of-macos.md` in this repository
  - This is a markdown version of Apple's documentation created using [llm.codes](https://steipete.me/posts/2025/llm-codes-transform-developer-docs?utm_source=chatgpt.com) by [@steipete](https://x.com/steipete)
  - Necessary because (as of July 2025) LLMs can't read Apple's documentation directly due to JavaScript requirements

## ✅ Correct SMAppService Configuration

### Main App Configuration

**Info.plist** - No SMAppService-specific keys needed:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Standard app keys only -->
</dict>
</plist>
```

**Entitlements**:
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

### Helper Daemon Configuration

**Info.plist** - Standard bundle keys only (no SMAuthorizedClients):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.keypath.helperpoc.helper</string>
    <key>CFBundleName</key>
    <string>helperpoc-helper</string>
    <!-- Other standard bundle keys -->
</dict>
</plist>
```

**Daemon plist** (`com.keypath.helperpoc.helper.plist`):
```xml
<dict>
    <key>Label</key>
    <string>com.keypath.helperpoc.helper</string>
    <key>BundleProgram</key>
    <string>Contents/MacOS/helperpoc-helper</string>
    <key>AssociatedBundleIdentifiers</key>
    <array>
        <string>com.keypath.helperpoc</string> <!-- Main app's identifier -->
    </array>
    <key>MachServices</key>
    <dict>
        <key>com.keypath.helperpoc.xpc</key>
        <true/>
    </dict>
</dict>
```

**Helper Entitlements**:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.developer.service-management.managed-by-main-app</key>
<true/>
```

### Swift Implementation

```swift
// CORRECT: Include .plist extension
private let helperPlistName = "com.keypath.helperpoc.helper.plist"

let service = SMAppService.daemon(plistName: helperPlistName)
try service.register()
```

## 🏗️ Bundle Structure

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

## 🧪 Building and Testing

### Prerequisites
- macOS 15.x Sequoia
- Xcode 16.x
- Apple Developer account with Developer ID certificates

### Steps
1. **Clone repository**: `git clone https://github.com/malpern/privileged_helper_help.git`
2. **Open Xcode project**: Open `helperpoc/helperpoc.xcodeproj`
3. **Configure signing**: Set your development team in project settings
4. **Build and run**: ⌘R
5. **Register helper**: Click "Register Helper" button
6. **Test result**: Pending - fixes have been applied but not yet tested

## 📖 Lessons Learned

### Common Pitfalls
1. **Don't mix SMJobBless with SMAppService** - They use completely different configuration
2. **Always include .plist extension** in `daemon(plistName:)`
3. **AssociatedBundleIdentifiers** should reference the main app, not the helper
4. **No SMAuthorizedClients or SMPrivilegedExecutables** with SMAppService

### Key Differences: SMJobBless vs SMAppService

| Feature | SMJobBless (Legacy) | SMAppService (Modern) |
|---------|-------------------|---------------------|
| macOS Version | 10.6-13.0 | 13.0+ |
| Authorization | SMAuthorizedClients/SMPrivilegedExecutables | Automatic with proper bundle structure |
| Helper Location | Contents/Library/LaunchServices | Contents/Library/LaunchDaemons or LaunchAgents |
| Plist Reference | Without extension | With .plist extension |
| API | Deprecated | Current best practice |

## 🙏 Acknowledgments

- **Quinn "The Eskimo!"** @ Developer Technical Support @ Apple - For identifying the root cause and providing clear guidance
- **[@steipete](https://x.com/steipete)** - For creating [llm.codes](https://steipete.me/posts/2025/llm-codes-transform-developer-docs) which helped us create LLM-readable Apple documentation
- **The macOS developer community** - For ongoing support and collaboration

## 📈 Implementation Status

### ✅ Fixes Applied
- ✅ Removed legacy SMJobBless configuration keys
- ✅ Added .plist extension to daemon name
- ✅ Fixed AssociatedBundleIdentifiers to reference main app
- ✅ Full Developer ID signing and notarization maintained

### 🧪 Testing Status
- ⏳ **Build test**: Pending
- ⏳ **Registration test**: Pending
- ⏳ **Error 108 resolution**: Pending verification

### 🚀 Next Steps
1. Test the fixes to confirm Error 108 is resolved
2. If successful, integrate with Kanata keyboard remapper
3. Add production error handling
4. Implement full XPC communication protocol

## 🔗 Resources

- [Apple Developer Forums Thread](https://developer.apple.com/forums/thread/792826)
- [Apple Documentation: Updating helper executables](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- [Kanata Keyboard Remapper](https://github.com/jtroo/kanata)
- [llm.codes - Transform Developer Docs](https://steipete.me/posts/2025/llm-codes-transform-developer-docs)

---

*Last Updated: July 2025 - Root causes identified by Apple Developer Support, testing pending*