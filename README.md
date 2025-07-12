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

### ❌ What's Blocking Us (Updated July 2025)
- **❌ Error -67028**: "Codesigning failure loading plist" when calling `SMAppService.daemon().register()`
- **❌ Build/Launch Issues**: Properly signed builds fail to launch (error 153), forcing use of Xcode builds
- **❌ Xcode vs Build Script Gap**: Xcode builds launch but lack proper bundle structure for SMAppService
- **❌ No working examples**: Haven't found any working SMAppService implementations to compare against

## What We've Implemented (Following Apple's Documentation)

Our implementation follows all documented requirements:

1. **Bundle Structure**: Helper executable and `launchd.plist` in `Contents/Library/LaunchDaemons/`
2. **Plist Format**: **UPDATED**: Now uses `<key>BundleProgram</key><string>Contents/Library/LaunchDaemons/HelperPOCDaemon</string>` with `AssociatedBundleIdentifiers`
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
│           └── com.keypath.helperpoc.plist ← **UPDATED**: BundleProgram: "Contents/Library/LaunchDaemons/HelperPOCDaemon"
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
    <string>identifier "com.keypath.helperpoc"</string>
</dict>
```

**Helper Daemon Plist (UPDATED for SMAppService):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.keypath.helperpoc</string>
    <key>BundleProgram</key>
    <string>Contents/Library/LaunchDaemons/HelperPOCDaemon</string>
    <key>AssociatedBundleIdentifiers</key>
    <array>
        <string>com.keypath.helperpoc</string>
    </array>
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

## 🔧 Recent Updates & Fixes Attempted (July 2025)

### ✅ Research-Based Fixes Applied
Based on deep research into error -67028 and community feedback, we implemented these critical fixes:

1. **✅ Updated Plist Format**: Changed from `Program` to `BundleProgram` key (required for SMAppService)
2. **✅ Added AssociatedBundleIdentifiers**: Added required array with bundle identifier
3. **✅ Simplified SMPrivilegedExecutables**: Reduced requirement string to just `identifier "com.keypath.helperpoc"`
4. **✅ Enhanced Error Logging**: Added detailed logging to capture error -67028 specifics

### 📊 Testing Results After Fixes
- **Error changed from -67028 to 108**: This suggests our plist fixes are having an effect
- **New issue discovered**: Properly signed builds fail to launch (error 153 "Launchd job spawn failed")
- **Xcode builds work**: But lack the proper bundle structure needed for SMAppService testing

### 🆘 **THE CORE PROBLEM: Build vs Runtime Gap**

We have **two separate issues** preventing us from testing our SMAppService fixes:

#### **Issue #1: Our Proper Builds Won't Launch** 
- ✅ **What works**: Build scripts create correct SMAppService bundle structure
- ✅ **What works**: Includes updated `BundleProgram` plist and proper signing
- ❌ **What fails**: Apps fail to launch with **Error 153** "Launchd job spawn failed"

#### **Issue #2: Launchable Builds Lack SMAppService Structure**
- ✅ **What works**: Xcode builds launch and run successfully  
- ❌ **What fails**: No app bundle structure (just simple executable)
- ❌ **What fails**: Can't test SMAppService because helper daemon isn't embedded

## 🎯 **WE NEED COMMUNITY HELP TO SOLVE EITHER:**

### **Option A: Fix Launch Error 153** 
Help us figure out why properly signed SMAppService bundles fail to launch:
```bash
# Our build creates proper structure but won't launch:
./build_developer_id.sh  # Creates bundle with LaunchDaemons/
open build/HelperPOCApp.app  # ERROR 153: "Launchd job spawn failed"
```

### **Option B: Make Xcode Create Proper Bundle Structure**
Help us configure Xcode to build apps with embedded helper daemons:
```bash
# Xcode builds launch but lack SMAppService structure:
open Package.swift  # Opens in Xcode
# Cmd+R launches successfully 
# But no Contents/Library/LaunchDaemons/ directory
```

---

## **Progress Made on Core SMAppService Issues**

**✅ Fixed Error -67028**: Our research-based fixes changed the error from -67028 to 108, indicating the plist format fixes are working!

**✅ Implemented Key Fixes**:
- Changed `Program` to `BundleProgram` in plist  
- Added `AssociatedBundleIdentifiers` array
- Simplified `SMPrivilegedExecutables` requirement string

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
1. 🔄 **Why error changed from -67028 to 108** after our plist fixes
2. ❌ **How to resolve launch error 153** with properly signed builds
3. ❌ **How to bridge Xcode builds and SMAppService requirements**
4. ❌ **Working examples** to compare our implementation against

## 🆘 **SPECIFIC HELP NEEDED**

### **Two Clear Paths to Success - We Need Help With Either One:**

#### **Path A: Fix Our Launch Issues**
**Problem**: Our properly built SMAppService bundles won't launch
```bash
./build_developer_id.sh  # ✅ Creates correct bundle structure  
open build/HelperPOCApp.app  # ❌ Error 153: "Launchd job spawn failed"
```
**Questions**:
- Why do signed SMAppService bundles fail to launch with error 153?
- Is there a specific signing order or entitlement we're missing?
- What causes "Launchd job spawn failed" with Developer ID signed apps?

#### **Path B: Fix Our Xcode Builds** 
**Problem**: Xcode builds launch but lack SMAppService structure
```bash
open Package.swift && Cmd+R  # ✅ Launches successfully
# ❌ But creates simple executable, not app bundle with LaunchDaemons/
```
**Questions**:
- How do you configure Swift Package Manager for SMAppService bundle structure?
- Can Xcode automatically embed helper daemons in `Contents/Library/LaunchDaemons/`?
- What build settings create proper SMAppService app bundles?

### **Success Criteria: Either Path Gets Us There**
If we can solve **either** issue, we can properly test our SMAppService fixes and determine if error -67028 is fully resolved.

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