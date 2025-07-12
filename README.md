# macOS Privileged Helper with SMAppService - Help Still Needed! 🆘

This repository contains a proof-of-concept implementation of a privileged helper using Apple's modern `SMAppService` API. Despite comprehensive testing and following all Apple documentation, **we're still encountering errors and need community help to resolve them.**

**Updated July 2025: Added comprehensive testing results - but still need help with remaining issues!**

## TL;DR: Key Findings

Our research reveals **significant differences** in SMAppService behavior across macOS versions:

### ✅ macOS 15.5 Sequoia (Stable Release)
- **SMAppService API**: ✅ Functional and responsive  
- **Registration Attempts**: ✅ Processes requests (though may fail on code signing validation)
- **Error Pattern**: Specific error codes (-67028) indicating validation issues
- **Developer Experience**: Much better than beta versions

### ❌ macOS 16 Beta (Tahoe - Darwin 25.0.0)
- **SMAppService API**: ❌ Fundamentally broken
- **Registration Attempts**: ❌ Complete failure
- **Error Pattern**: Generic "Unable to read plist" errors
- **Status**: Appears to be a beta OS bug

### 🎯 Recommended Target
**macOS 15.5 Sequoia appears to be the most reliable platform for SMAppService development.**

## What We've Implemented (Following Apple's Documentation)

Our implementation follows all documented requirements:

1. **Bundle Structure**: Helper executable and `launchd.plist` in `Contents/Library/LaunchDaemons/`
2. **Plist Format**: Uses relative paths with `<key>Program</key><string>HelperPOCDaemon</string>`
3. **Code Signing**: Developer ID certificate with hardened runtime
4. **Notarization**: Full Apple notarization and stapling
5. **Entitlements**: Proper entitlements including `com.apple.developer.service-management.managed-by-main-app`

## Bundle Structure Overview

```
HelperPOCApp.app/
├── Contents/
│   ├── Info.plist ← Contains SMPrivilegedExecutables key
│   ├── MacOS/
│   │   └── HelperPOCApp ← Main app executable (signed & notarized)
│   └── Library/
│       └── LaunchDaemons/ ← CRITICAL: Helper must be here
│           ├── HelperPOCDaemon ← Helper executable (signed & notarized)
│           └── com.keypath.helperpoc.plist ← Program: "HelperPOCDaemon"
```

## Testing Results by macOS Version

### macOS 16 Beta (Tahoe - Darwin 25.0.0) ❌

**Error Pattern:**
```
The operation couldn't be completed. Unable to read plist: com.keypath.helperpoc
```

**Symptoms:**
- Complete SMAppService failure
- Manual `launchctl` commands fail with "Input/output error"
- System-level daemon registration broken
- No helpers appear in System Settings → Login Items

**Status:** Likely a macOS 16 beta bug affecting core ServiceManagement functionality.

### macOS 15.5 Sequoia (Stable) ✅⚠️

**Error Pattern:**
```
Codesigning failure loading plist: com.keypath.helperpoc code: -67028
```

**Symptoms:**
- SMAppService API responds and processes requests
- Specific error codes indicating validation steps
- App builds, signs, and notarizes successfully
- Better compatibility than beta versions

**Analysis:** The error suggests code signing validation issues rather than fundamental API problems. This is a **much better** starting point for development than the complete failure seen in macOS 16 beta.

## What We're Trying to Accomplish

We're building an app that integrates with [Kanata](https://github.com/jtroo/kanata), a cross-platform keyboard remapper. Our macOS implementation requires:

1. Register a privileged daemon using the modern `SMAppService` API
2. Execute root-level operations for system-wide keyboard event interception  
3. Communicate with the main app via XPC
4. Work reliably on macOS 14+ (Sonoma, Sequoia)

## Complete Implementation Details

### Code Signing & Notarization ✅

Our testing included the full distribution pipeline:

```bash
# 1. Sign with Developer ID certificate
codesign --force --sign "Developer ID Application: [Name] ([TeamID])" \
    --entitlements [App].entitlements \
    --options runtime \
    --timestamp \
    [App].app

# 2. Submit for notarization  
xcrun notarytool submit [App].zip --keychain-profile "Developer-altool" --wait

# 3. Staple notarization ticket
xcrun stapler staple [App].app

# 4. Verify with Gatekeeper
spctl -a -vv [App].app
# Result: "accepted, source=Notarized Developer ID"
```

**Result**: ✅ All steps completed successfully on macOS 15.5

### Key Configuration Files

**Main App Info.plist:**
```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.keypath.helperpoc</key>
    <string>identifier "com.keypath.helperpoc" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "X2RKZ5TG99"</string>
</dict>
```

**Helper Daemon Plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.keypath.helperpoc</string>
    <key>Program</key>
    <string>HelperPOCDaemon</string>
    <key>MachServices</key>
    <dict>
        <key>com.keypath.helperpoc.xpc</key>
        <true/>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

**Entitlements:**

*Main App (HelperPOCApp.entitlements):*
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>com.keypath.helperpoc.xpc</string>
</array>
<key>com.apple.developer.service-management.managed-by-main-app</key>
<true/>
```

*Helper Daemon (HelperPOCDaemon.entitlements):*
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

### Everything We've Tested

#### 1. Code Signing Approaches ✅
- ✅ Developer ID Application certificate  
- ✅ Apple Development certificate (development only)
- ✅ Ad-hoc signing (local testing)
- ✅ Hardened Runtime enabled
- ✅ Proper timestamp signing

#### 2. Notarization Pipeline ✅
- ✅ Full Apple notarization process
- ✅ Notarization ticket stapling
- ✅ Gatekeeper verification: "Notarized Developer ID"
- ✅ App-specific password authentication

#### 3. Bundle Structure Validation ✅
- ✅ Helper in `Contents/Library/LaunchDaemons/`
- ✅ Relative paths in plist `Program` key
- ✅ Proper `SMPrivilegedExecutables` configuration
- ✅ Code signing requirement strings

#### 4. Entitlements Research ✅
- ✅ `com.apple.developer.service-management.managed-by-main-app`
- ✅ Sandbox configuration (enabled for helper, disabled for main app)
- ✅ XPC service entitlements
- ✅ Network client permissions

#### 5. macOS Version Compatibility ✅
- ✅ macOS 15.5 Sequoia: SMAppService functional
- ❌ macOS 16 Beta: Complete SMAppService failure
- 📋 Recommendation: Target macOS 15.x for development

## Environment Details

**Testing Platforms:**
- **macOS 15.5 Sequoia** (Darwin 24.x) - Stable release
- **macOS 16 Beta Tahoe** (Darwin 25.x) - Beta release with known issues

**Hardware:** Apple Silicon (arm64)  
**Development Tools:** Swift 5.9+, Xcode 16.2, Command Line Tools  
**Code Signing:** Developer ID Application certificate with full notarization

## Key Insights & Recommendations

### ✅ What Works (macOS 15.5 Sequoia)
1. **SMAppService API is functional** - Responds to registration requests
2. **Proper development workflow** - Build, sign, notarize, test cycle works
3. **Specific error feedback** - Clear error codes for debugging
4. **System integration** - Apps can be properly distributed and installed

### ❌ What's Broken (macOS 16 Beta)
1. **Fundamental API failure** - SMAppService doesn't process requests
2. **System-level issues** - Even manual launchctl commands fail
3. **Generic error messages** - "Unable to read plist" with no useful details
4. **Complete workflow breakdown** - No viable development path

### 🎯 Development Recommendations

1. **Target macOS 15.x** for SMAppService development
2. **Implement full notarization** pipeline from the start
3. **Use Developer ID certificates** (not just development certificates)
4. **Test on stable releases** rather than beta versions
5. **Expect error -67028** on Sequoia and debug from there

## How to Test This Implementation

**📋 Quick Start: See [SETUP.md](SETUP.md) for detailed setup instructions**

1. **Clone this repository**
2. **Update code signing identity** in `build_and_sign.sh`
3. **Run the build:**
   ```bash
   ./build_and_sign.sh    # Main build script
   ```
4. **Test on macOS 15.5** (recommended) or macOS 14.x

**Alternative**: Open `Package.swift` in Xcode for the best debugging experience.

## Questions for the Community

1. **Has anyone resolved the -67028 error** on macOS 15.5 Sequoia?
2. **Are there additional entitlements** required for SMAppService?
3. **Is there a workaround** for the macOS 16 beta issues?
4. **Should we expect SMAppService fixes** in later macOS 16 builds?

## Current Status: Still Need Help! 🆘

**What's Working**: ✅ 
- ✅ Full implementation following Apple's guidelines
- ✅ Complete code signing and notarization pipeline  
- ✅ SMAppService API responds on macOS 15.5

**What's Still Broken**: ❌
- ❌ **Error -67028 on macOS 15.5**: "Codesigning failure loading plist" 
- ❌ **Complete failure on macOS 16 beta**: "Unable to read plist"
- ❌ **Cannot register privileged helpers** on either platform

**We Need Help With**:
1. **Resolving error -67028** on macOS 15.5 Sequoia  
2. **Understanding what we're missing** in our implementation
3. **Working examples** of SMAppService on modern macOS
4. **Alternative approaches** if SMAppService is fundamentally broken

## 🆘 Specific Help Needed

**We've done extensive research and testing, but we're still stuck. Can you help?**

### 🎯 Most Urgent: Error -67028 on macOS 15.5
```
Codesigning failure loading plist: com.keypath.helperpoc code: -67028
```
- **What we've tried**: Developer ID signing, full notarization, correct entitlements
- **What works**: App builds, signs, notarizes, and passes Gatekeeper  
- **What fails**: SMAppService.daemon().register() throws this error
- **Question**: What are we missing for the plist validation to pass?

### 🎯 Secondary: macOS 16 Beta Complete Failure
```
The operation couldn't be completed. Unable to read plist: com.keypath.helperpoc
```
- **Status**: Appears to be a fundamental macOS 16 beta bug
- **Question**: Has anyone gotten SMAppService working on macOS 16?

### 🎯 General Questions
1. **Do you have a working SMAppService implementation?** Can you share code or guidance?
2. **Are there undocumented requirements** for SMAppService that we're missing?
3. **Should we abandon SMAppService** and use a different approach?
4. **Is this specific to our use case** (keyboard remapping) or universal?

## How You Can Help

**If you've successfully used SMAppService:**
- Share your working code (anonymized is fine)
- Tell us what entitlements/requirements we might be missing
- Let us know what macOS versions work for you

**If you're also stuck:**
- Try our implementation and report your results
- Share any different error messages you're seeing
- Compare notes on what you've tried

**If you have alternatives:**
- Suggest other approaches for privileged helper registration
- Share experiences with older APIs (SMJobBless, etc.)

**Contact Methods:**
- **Open an issue** with suggestions, working examples, or questions
- **Submit a PR** if you spot something we missed
- **Reach out on Twitter**: [@malpern](https://twitter.com/malpern)
- **Email**: malpern@me.com (for sensitive/proprietary discussions)

We've been stuck on this for weeks and would be incredibly grateful for any help! 🙏

---

*Last Updated: July 2025 - Added comprehensive testing results for macOS 15.5 Sequoia*