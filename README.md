# macOS Privileged Helper with SMAppService - Help Needed! 🆘

This repository contains a proof-of-concept implementation of a privileged helper using Apple's modern `SMAppService` API. Despite following all documented guidelines and implementing numerous fixes suggested by experienced macOS developers, we're encountering a persistent error on macOS 15 beta that we cannot resolve.

**We would greatly appreciate any insights or suggestions from the macOS developer community!**

## TL;DR: The 5 Non-Negotiable Requirements

If your `SMAppService` helper is failing, you have likely missed one of these five critical steps. This guide details each one.

1. **Correct Bundle Structure:** The helper executable and its `launchd.plist` **must** be in `YourApp.app/Contents/Library/LaunchDaemons/`.
2. **Correct `launchd.plist`:** It **must** use the `<key>Program</key>` and the value must be just the helper's filename (e.g., `<string>HelperPOCDaemon</string>`). The path is relative to the plist's location.
3. **Correct Main App `Info.plist`:** It **must** contain the `SMPrivilegedExecutables` key, with a code signing requirement string that exactly matches your helper's signature and Team ID.
4. **Correct Entitlements (Both App & Helper):**
   - **Main App:** Must have the `com.apple.developer.service-management.managed-by-main-app` entitlement.
   - **Helper Daemon:** Must have the `com.apple.security.app-sandbox` entitlement.
5. **Correct Code Signing:** The main app and the helper **must** be signed with the same Developer ID certificate and use the Hardened Runtime.

## What We're Trying to Accomplish

We're building an app that integrates with [Kanata](https://github.com/jtroo/kanata), a cross-platform keyboard remapper. Our macOS implementation requires:

1. Register a privileged daemon using the modern `SMAppService` API (replacing deprecated `SMJobBless`)
2. Execute root-level operations (Kanata requires root access for system-wide keyboard event interception)
3. Communicate with the main app via XPC
4. Work reliably on macOS 14+ (Sonoma, Sequoia)

## The Problem

On macOS 15 beta (Darwin 25.0.0), we consistently get this error:

```
The operation couldn't be completed. Unable to read plist: com.keypath.helperpoc
```

This occurs when calling:
```swift
SMAppService.daemon(plistName: "com.keypath.helperpoc").register()
```

Even more concerning: manual `launchctl` commands also fail with "Input/output error", suggesting a system-level issue.

## Apple Documentation We're Following

We've carefully followed Apple's official documentation:

1. [Updating helper executables from earlier versions of macOS](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
2. [SMAppService API Reference](https://developer.apple.com/documentation/servicemanagement/smappservice)
3. [Creating a launch daemon](https://developer.apple.com/documentation/servicemanagement/smappservice/daemon(plistname:))

Key requirements from the docs:
- Helper daemon must be in `Contents/Library/LaunchDaemons/`
- Plist must use relative paths for embedded helpers
- Main app must declare `SMPrivilegedExecutables` in Info.plist
- Proper code signing with Developer ID

## Our Implementation

### Bundle Structure ✅
```
HelperPOCApp.app/
├── Contents/
│   ├── Info.plist                    # Contains SMPrivilegedExecutables
│   ├── MacOS/
│   │   └── HelperPOCApp              # Main application
│   └── Library/
│       └── LaunchDaemons/
│           ├── HelperPOCDaemon       # Privileged helper executable
│           └── com.keypath.helperpoc.plist  # Launch daemon plist
```

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

#### Common `launchd.plist` Mistakes

The `Program` key is critical. Any of these common mistakes will cause `launchctl` to fail with a generic `Input/output error` or `SMAppService` to fail with "Unable to read plist".

```xml
<!-- WRONG: BundleProgram is for other contexts and often fails here. -->
<key>BundleProgram</key>
<string>HelperPOCDaemon</string>

<!-- WRONG: An absolute path will fail because the app bundle is not at a fixed location. -->
<key>Program</key>
<string>/Applications/YourApp.app/Contents/Library/LaunchDaemons/HelperPOCDaemon</string>

<!-- WRONG: A nested path is incorrect because the path is relative to the plist itself. -->
<key>Program</key>
<string>Contents/Library/LaunchDaemons/HelperPOCDaemon</string>
```

## Everything We've Tried

### 1. Plist Path Formats
- ❌ `BundleProgram` with nested path: `Contents/Library/LaunchDaemons/HelperPOCDaemon`
- ❌ `Program` with absolute path: `/Library/PrivilegedHelperTools/com.keypath.helperpoc`
- ❌ `Program` with relative path: `HelperPOCDaemon` (current implementation)
- ❌ `ProgramArguments` array format

### 2. Code Signing & Notarization
- ✅ Signed with Developer ID Application certificate
- ✅ Helper daemon has explicit identifier: `com.keypath.helperpoc`
- ✅ All signatures verify with `codesign --verify`
- ✅ App is fully notarized and stapled
- ✅ `spctl -a -vvv` shows: "accepted, source=Notarized Developer ID"

### 3. Entitlements Attempted
**Main App Entitlements:**
- ✅ `com.apple.security.app-sandbox = false`
- ✅ `com.apple.security.temporary-exception.mach-lookup.global-name`
- ✅ `com.apple.developer.service-management.managed-by-main-app = true` (suspected new requirement)

**Helper Daemon Entitlements:**
- ❌ `com.apple.security.app-sandbox = false` (original)
- ❌ `com.apple.security.app-sandbox = true` (tested as potential new requirement)

### 4. Manual Testing
```bash
# Direct plist validation
plutil -lint com.keypath.helperpoc.plist  # Result: OK

# Manual launchctl attempts (all fail with "Input/output error")
sudo launchctl load -w /path/to/plist
sudo launchctl bootstrap system /path/to/plist

# Even with simplified test plists containing absolute paths
```

### 5. System-Level Debugging
- Checked for existing services: `launchctl list | grep keypath` (none found)
- Monitored system logs: `log stream --predicate 'subsystem == "com.apple.servicemanagement"'`
- Verified no quarantine attributes
- Checked extended attributes (found Dropbox attrs, but shouldn't affect functionality)

### How to Verify Your Signatures

Don't just sign and hope. Use these commands in Terminal to verify what the system sees.

**1. Verify the main app's signature and entitlements:**
```bash
codesign -dv --entitlements - /Applications/YourApp.app
```
- Look for `Authority=Developer ID Application: Your Name (YOUR_TEAM_ID)`.
- Look for `TeamIdentifier=YOUR_TEAM_ID`.
- In the Entitlements blob, make sure you see `com.apple.developer.service-management.managed-by-main-app`.

**2. Verify the helper daemon's signature and entitlements:**
```bash
codesign -dv --entitlements - /Applications/YourApp.app/Contents/Library/LaunchDaemons/YourHelper
```
- The `Authority` and `TeamIdentifier` must **match** the main app.
- The `Identifier` must match what's in your `SMPrivilegedExecutables` key (e.g., `com.yourcompany.helper`).
- In the Entitlements blob, make sure you see `com.apple.security.app-sandbox`.

## Environment Details

- **macOS Version**: 15.x beta (Darwin 25.0.0)
- **Hardware**: Apple Silicon (arm64)
- **Development Tools**: Swift 5.9+, Xcode Command Line Tools
- **Code Signing**: Developer ID Application: Micah Alpern (X2RKZ5TG99)

## What We Suspect

Given that both `SMAppService` and manual `launchctl` commands fail with the same error, we believe this is either:

1. **A macOS 15 beta bug** - The system-level daemon registration mechanism has issues
2. **An undocumented security requirement** - macOS 15 may require additional entitlements or configuration we haven't discovered

## How to Test

1. Clone this repository
2. Run `./build_and_sign.sh` (you'll need to update the Developer ID)
3. Open `build/HelperPOCApp.app`
4. Click "Register Helper"
5. Observe the error in the UI or check `/tmp/helperpoc-app.log`

## Questions for the Community

1. **Has anyone successfully used `SMAppService` for privileged daemons on macOS 15 beta?**
2. **Are there new, undocumented requirements for privileged helpers in macOS 15?**
3. **Is the "Unable to read plist" error familiar to anyone? What was the root cause?**
4. **Should we be using a different approach entirely for modern macOS?**

## Request for Help

We've exhausted all documented approaches and many undocumented ones. If you have experience with:
- `SMAppService` on recent macOS versions
- Privileged helper development
- macOS 15 beta quirks
- Alternative approaches for system-level daemons

**We would be incredibly grateful for any insights, suggestions, or even just confirmation that others are experiencing similar issues.**

Feel free to:
- Open an issue with suggestions
- Submit a PR if you spot something we missed
- Reach out on Twitter: [@malpern](https://twitter.com/malpern)

Thank you so much for taking the time to look at this! 🙏

---

*Note: We understand testing on macOS 14 would help isolate the issue, but we currently only have access to macOS 15 beta. If you've tested similar code on macOS 14, we'd love to hear about your experience.*