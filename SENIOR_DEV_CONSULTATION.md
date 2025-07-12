# SMAppService Implementation Issues - Senior Developer Consultation

## Background & Context

We're implementing a privileged helper daemon using Apple's modern `SMAppService` API (replacement for deprecated `SMJobBless`) on macOS 15.5 Sequoia. Despite following Apple's documentation and implementing research-based fixes, we're encountering critical build/launch issues that prevent proper testing.

## The Use Case

Building a macOS app that integrates with [Kanata](https://github.com/jtroo/kanata) (cross-platform keyboard remapper) requiring:
- Privileged daemon for system-wide keyboard event interception
- XPC communication between main app and helper
- Modern SMAppService API (not legacy SMJobBless)
- Target: macOS 14+ (Sonoma, Sequoia)

## Current Implementation

### Architecture
```
HelperPOCApp.app/
├── Contents/
│   ├── Info.plist ← Contains SMPrivilegedExecutables
│   ├── MacOS/HelperPOCApp ← Main SwiftUI app
│   └── Library/LaunchDaemons/ ← Required by SMAppService
│       ├── HelperPOCDaemon ← Privileged helper executable  
│       └── com.keypath.helperpoc.plist ← launchd plist
```

### Key Files

**Main App Info.plist (SMPrivilegedExecutables):**
```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.keypath.helperpoc</key>
    <string>identifier "com.keypath.helperpoc"</string>
</dict>
```

**Helper Daemon Plist (Updated for SMAppService):**
```xml
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
```

**Main App Entitlements:**
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
<key>com.apple.developer.service-management.managed-by-main-app</key>
<true/>
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>com.keypath.helperpoc.xpc</string>
</array>
```

**Helper Daemon Entitlements:**
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

## Progress Made

### ✅ Research-Based Fixes Applied
1. **Plist Format**: Changed from `Program` to `BundleProgram` (critical for SMAppService)
2. **Bundle Association**: Added `AssociatedBundleIdentifiers` array
3. **Simplified Requirements**: Reduced `SMPrivilegedExecutables` to just identifier check
4. **Enhanced Logging**: Added detailed error diagnostics

### ✅ Evidence Fixes Are Working
- **Error changed from -67028 to 108** after applying plist fixes
- This indicates SMAppService can now read our plist format
- Error 108 suggests a different validation issue (not plist format)

## 🆘 CRITICAL BLOCKERS

### The Core Problem: Build vs Runtime Gap

We have **two separate build approaches** with **opposite problems**:

#### Issue #1: Build Scripts Create Proper Structure → Won't Launch
```bash
./build_developer_id.sh  # Creates correct SMAppService bundle
open build/HelperPOCApp.app  # ❌ ERROR 153: "Launchd job spawn failed"
```

**What Works:**
- ✅ Proper app bundle structure with `Contents/Library/LaunchDaemons/`
- ✅ Updated `BundleProgram` plist format
- ✅ Developer ID certificate signing with hardened runtime
- ✅ Full notarization and stapling
- ✅ All code signing verification passes

**What Fails:**
- ❌ Apps refuse to launch with error 153 "Launchd job spawn failed"
- ❌ Cannot test SMAppService because app won't start

#### Issue #2: Xcode Builds Launch → Lack SMAppService Structure  
```bash
open Package.swift  # Opens in Xcode
# Cmd+R launches successfully but creates simple executable
```

**What Works:**
- ✅ Apps launch and run perfectly
- ✅ Can test basic UI and functionality
- ✅ No signing or launch issues

**What Fails:**
- ❌ No app bundle structure (just executable in DerivedData)
- ❌ No embedded helper daemon
- ❌ Cannot test SMAppService registration

### Testing Limitation
We **cannot fully test our SMAppService fixes** because:
- Proper builds won't launch (can't run the app)
- Launchable builds lack SMAppService structure (can't test registration)

## Technical Details

### Build Process (build_developer_id.sh)
```bash
# 1. Swift build
swift build -c release

# 2. Create bundle structure  
mkdir -p build/HelperPOCApp.app/Contents/{MacOS,Library/LaunchDaemons}

# 3. Copy executables
cp .build/release/HelperPOCApp build/HelperPOCApp.app/Contents/MacOS/
cp .build/release/HelperPOCDaemon build/HelperPOCApp.app/Contents/Library/LaunchDaemons/

# 4. Generate Info.plist with SMPrivilegedExecutables

# 5. Sign helper daemon first
codesign --force --sign "Developer ID Application: [Name] ([TeamID])" \
    --entitlements HelperPOCDaemon.entitlements \
    --options runtime \
    --identifier "com.keypath.helperpoc" \
    --timestamp \
    "build/HelperPOCApp.app/Contents/Library/LaunchDaemons/HelperPOCDaemon"

# 6. Sign main app
codesign --force --sign "Developer ID Application: [Name] ([TeamID])" \
    --entitlements HelperPOCApp.entitlements \
    --options runtime \
    --timestamp \
    "build/HelperPOCApp.app/Contents/MacOS/HelperPOCApp"

# 7. Sign app bundle
codesign --force --sign "Developer ID Application: [Name] ([TeamID])" \
    --entitlements HelperPOCApp.entitlements \
    --options runtime \
    --timestamp \
    "build/HelperPOCApp.app"
```

### Error 153 Details
- Occurs when trying to launch via Finder or `open` command
- "Launchd job spawn failed" suggests process creation issue
- All code signing verification passes:
  ```bash
  codesign --verify --verbose build/HelperPOCApp.app  # ✅ PASSES
  spctl -a build/HelperPOCApp.app  # ✅ "accepted source=Notarized Developer ID"
  ```

### Swift Package Manager Setup
```swift
// Package.swift
let package = Package(
    name: "PrivilegedHelperPOC",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HelperPOCApp", targets: ["HelperPOCApp"]),
        .executable(name: "HelperPOCDaemon", targets: ["HelperPOCDaemon"]),
    ],
    targets: [
        .executableTarget(
            name: "HelperPOCApp",
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        .executableTarget(
            name: "HelperPOCDaemon", 
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
    ]
)
```

## Questions for Senior Developer

### Primary Questions: Build/Launch Issues

1. **Error 153 Root Cause**: What typically causes "Launchd job spawn failed" with properly signed macOS apps? Is this related to:
   - Signing order (helper → app → bundle)?
   - Entitlements conflicts?
   - Bundle structure issues?
   - Hardened runtime restrictions?

2. **SMAppService Bundle Requirements**: Are there specific requirements for app bundles containing SMAppService helpers that might cause launch failures?

3. **Code Signing for Embedded Helpers**: Is there a correct signing sequence for apps with embedded privileged helpers? Should we sign differently?

### Secondary Questions: Development Workflow

4. **Xcode + SMAppService**: How do production apps handle SMAppService development in Xcode? Do you:
   - Use build phases to create bundle structure?
   - Configure targets differently?
   - Use separate schemes for development vs distribution?

5. **Swift Package Manager**: Can SPM be configured to create proper app bundles with embedded resources like helper daemons?

### Debugging Questions

6. **Error 153 Diagnosis**: What's the best way to debug "Launchd job spawn failed"? Are there:
   - Console logs that provide more detail?
   - System-level diagnostics?
   - Code signing validation tools we should check?

7. **SMAppService vs SMJobBless**: Are there any gotchas when migrating from SMJobBless patterns to SMAppService that might explain our build issues?

### Validation Questions

8. **Our Approach**: Does our overall approach (build scripts + bundle structure + plist format) seem correct for SMAppService on macOS 15?

9. **Alternative Approaches**: Should we be using a completely different development/build strategy for SMAppService apps?

## Repository & Testing

**GitHub**: https://github.com/malpern/privileged_helper_help
**Quick Test**: 
```bash
git clone https://github.com/malpern/privileged_helper_help.git
cd privileged_helper_help
./build_developer_id.sh  # Update DEVELOPER_ID first
open build/HelperPOCApp.app  # Will fail with error 153
```

**Xcode Test**:
```bash
open Package.swift  # Opens in Xcode
# Cmd+R works but no SMAppService structure
```

## Success Criteria

If we can solve **either** issue:
1. **Fix launch error 153** → Can test SMAppService with proper bundle structure
2. **Make Xcode create proper bundles** → Can develop and test SMAppService in normal workflow

Either solution would allow us to validate whether our -67028 fixes actually resolve the core SMAppService registration issues.

---

*This document represents weeks of research, testing, and community feedback. We're confident in our SMAppService fixes but blocked by fundamental build/launch issues.*