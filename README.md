# macOS Privileged Helper with SMAppService - Help Still Needed! 🆘

This repository contains a proof-of-concept implementation of a privileged helper using Apple's modern `SMAppService` API. Despite comprehensive testing and following all Apple documentation, **we're still encountering errors and need community help to resolve them.**

**Updated July 2025: Added comprehensive testing results - but still need help with remaining issues!**

## TL;DR: Current Status on macOS Sequoia

**We have a complete implementation following Apple's documentation, but SMAppService registration fails with a specific error:**

### ✅ What's Working
- **Complete implementation**: Following all Apple documentation
- **Proper code signing**: Developer ID certificate with hardened runtime
- **Full notarization**: App passes Apple's security checks
- **SMAppService responds**: API processes requests (doesn't crash)

### ❌ What's Blocking Us
- **❌ Error -67028**: "Codesigning failure loading plist" when calling `SMAppService.daemon().register()`
- **❌ Helper registration fails**: Cannot register privileged helper on macOS 15.5 Sequoia
- **❌ No working examples**: Haven't found any working SMAppService implementations to compare against

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

## ❌ The Problem: Error -67028 on macOS Sequoia

When we call `SMAppService.daemon().register()`, we consistently get:

```
Codesigning failure loading plist: com.keypath.helperpoc code: -67028
```

### What This Error Means
- SMAppService can read our plist file ✅
- SMAppService attempts to validate our code signing ✅  
- The code signing validation fails with error -67028 ❌

### What We've Verified Works
- **App builds and runs**: No basic functionality issues
- **Code signing valid**: `codesign --verify` passes, `spctl -a` shows "Notarized Developer ID"
- **Bundle structure correct**: Helper in `Contents/Library/LaunchDaemons/` as required
- **Plist format valid**: `plutil -lint` passes, follows Apple's examples exactly
- **Entitlements present**: Including `com.apple.developer.service-management.managed-by-main-app`

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
- ✅ macOS 15.5 Sequoia: SMAppService API functional (but registration fails)
- ✅ macOS 14.x Sonoma: Should work (needs testing)
- 📋 Target: macOS 14+ (Sonoma, Sequoia)

## Environment Details

**Testing Platform:**
- **macOS 15.5 Sequoia** (Darwin 24.x) - Stable release

**Hardware:** Apple Silicon (arm64)  
**Development Tools:** Swift 5.9+, Xcode 16.2, Command Line Tools  
**Code Signing:** Developer ID Application certificate with full notarization

## ❌ Current Blockers

### Primary Issue: Error -67028
```
Codesigning failure loading plist: com.keypath.helperpoc code: -67028
```

**What we know:**
- Occurs during `SMAppService.daemon().register()` call
- All our code signing appears valid to other macOS tools
- SMAppService's internal validation is rejecting our setup

**What we need help with:**
- ❌ What specific code signing requirement are we missing?
- ❌ Are there undocumented entitlements for SMAppService?
- ❌ Is our `SMPrivilegedExecutables` requirement string incorrect?

### Secondary Issues
- ❌ **No working examples**: Haven't found any public SMAppService implementations to compare
- ❌ **Limited debugging info**: Error -67028 doesn't provide specific guidance
- ❌ **Unclear documentation**: Apple's docs seem incomplete for modern requirements

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

## ❌ We Need Your Help!

### 🎯 Specific Questions
1. **Have you successfully used SMAppService on macOS Sequoia?**
2. **What does error -67028 specifically mean and how do you fix it?**
3. **Are there undocumented requirements for SMAppService we're missing?**
4. **Do you have a working implementation we can compare against?**

## Current Status: Stuck on Error -67028! 🆘

**What's Working**: ✅ 
- ✅ Complete implementation following Apple's documentation
- ✅ Proper Developer ID signing and full notarization
- ✅ SMAppService API responds (doesn't crash or give generic errors)
- ✅ All macOS security tools validate our code signing

**What's Blocking**: ❌
- **❌ Error -67028**: SMAppService's internal validation rejects our helper
- **❌ Cannot register helper**: `SMAppService.daemon().register()` fails consistently  
- **❌ Missing requirements**: Something we're doing doesn't meet SMAppService's expectations

**We Need Help Understanding**:
1. ❌ **What triggers error -67028** and how to fix it
2. ❌ **Missing entitlements or requirements** for SMAppService
3. ❌ **Correct format** for `SMPrivilegedExecutables` requirement strings
4. ❌ **Working examples** to compare our implementation against

## 🆘 Specific Help Needed

**We've done extensive research and testing, but we're still stuck. Can you help?**

### 🎯 Primary Issue: Error -67028 on macOS Sequoia
```
Codesigning failure loading plist: com.keypath.helperpoc code: -67028
```
- **What we've tried**: Developer ID signing, full notarization, proper entitlements
- **What works**: App builds, signs, notarizes, and passes all macOS security checks
- **What fails**: SMAppService's internal validation rejects our helper during registration
- **Question**: What specific requirement are we missing?

### 🎯 General Questions
1. **Do you have a working SMAppService implementation on macOS Sequoia?** 
2. **What does error code -67028 specifically indicate?**
3. **Are there undocumented entitlements or requirements for modern SMAppService?**
4. **Should we use a different approach for privileged helpers on macOS 15+?**

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

We've been stuck on this for weeks and would be incredibly grateful for any help! 🙏

---

*Last Updated: July 2025 - Added comprehensive testing results for macOS 15.5 Sequoia*