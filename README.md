# macOS SMAppService Implementation - Error 108 "Unable to read plist"

This repository contains a **complete SMAppService implementation** that demonstrates a persistent issue on macOS 15 Sequoia. We have a fully working build system and proper bundle structure, but SMAppService registration consistently fails with Error 108.

**Updated January 2025: Need community help to understand Error 108 root cause**

## 🚨 **The Core Problem**

SMAppService registration fails with Error 108 "Unable to read plist" despite having:
- ✅ Correct bundle structure
- ✅ Proper code signing  
- ✅ Valid plist configuration
- ✅ All documented requirements met

## 📊 **What We Know For Certain**

### ✅ **Working Implementation**
- **Xcode project builds successfully**: Both main app and helper daemon targets
- **Proper bundle structure**: Helper embedded in `Contents/MacOS/`, plist in `Contents/Library/LaunchDaemons/`
- **Clean code signing**: Works with Development and Developer ID certificates
- **App launches perfectly**: No build or launch issues
- **Plist is valid**: Passes `plutil -lint` validation
- **Bundle structure verified**: All files in expected locations

### ✅ **Technical Implementation Complete**
- **SMAppService registration logic**: Complete Swift implementation
- **XPC communication protocol**: Ready for privileged operations
- **Copy Files build phases**: Proper helper embedding workflow
- **SMPrivilegedExecutables**: Correct requirement string configured
- **Enhanced logging**: Detailed error diagnostics

## ❌ **What's Not Working**

### **Error 108 "Unable to read plist"**
```
[ERROR] Helper registration failed: The operation couldn't be completed. 
Unable to read plist: com.keypath.helperpoc (Code: 108, Domain: SMAppServiceErrorDomain)
```

**This error occurs when:**
- App builds and launches successfully
- User clicks "Register Helper" button
- SMAppService attempts to register the helper daemon
- System cannot read the helper's plist file

## 🔧 **Complete Technical Implementation**

### **Project Structure (✅ Working)**
```
helperpoc/
├── helperpoc.xcodeproj              ← Native Xcode project
├── helperpoc/                       ← Main app target
│   ├── ContentView.swift            ← SMAppService UI with test buttons
│   ├── HelperManager.swift          ← SMAppService registration logic
│   ├── helperpoc.entitlements       ← App entitlements (no sandbox)
│   ├── Info.plist                   ← Contains SMPrivilegedExecutables
│   └── com.keypath.helperpoc.plist  ← Helper daemon plist
└── helperpoc-helper/                ← Helper daemon target
    ├── main.swift                   ← Helper daemon entry point
    ├── HelperTool.swift             ← Privileged operations
    └── helperpoc-helper.entitlements ← Helper entitlements (sandboxed)
```

### **Resulting Bundle Structure (✅ Verified Correct)**
```
helperpoc.app/
├── Contents/
│   ├── Info.plist                           ← Contains SMPrivilegedExecutables
│   ├── MacOS/
│   │   ├── helperpoc                        ← Main app executable  
│   │   └── helperpoc-helper                 ← Helper daemon embedded
│   └── Library/
│       └── LaunchDaemons/
│           └── com.keypath.helperpoc.plist  ← Helper plist in correct location
```

### **SMPrivilegedExecutables Configuration (✅ Applied)**
```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.keypath.helperpoc</key>
    <string>identifier "com.keypath.helperpoc" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = X2RKZ5TG99</string>
</dict>
```

### **Helper Daemon Plist (✅ Applied)**
```xml
<key>Label</key>
<string>com.keypath.helperpoc</string>
<key>BundleProgram</key>
<string>Contents/MacOS/helperpoc-helper</string>
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

## 🤔 **What We Don't Know**

### **Root Cause of Error 108**
- **What "Unable to read plist" actually means**: File permissions? Format? Content? Access rights?
- **macOS 15 specific requirements**: Are there undocumented changes in Sequoia?
- **Development vs production differences**: Does this need notarization even for testing?
- **Entitlement requirements**: Are there missing entitlements we don't know about?

### **Debugging Questions**
1. **File access**: Can SMAppService actually access files in the bundle?
2. **Sandboxing**: Does the helper being sandboxed affect plist reading?
3. **Bundle validation**: Are there additional bundle requirements for macOS 15?
4. **System logs**: What do system logs show when Error 108 occurs?

## 🆘 **How You Can Help**

### **If You Have SMAppService Working on macOS 15**
- **Share your exact configuration**: Entitlements, plist format, bundle structure
- **Compare with our implementation**: What's different in your working setup?
- **Share your Xcode project**: Even a minimal working example would help enormously

### **If You're Getting the Same Error 108**
- **Test our implementation**: Does it reproduce the exact same issue?
- **Try on different macOS versions**: Does it work on macOS 14 vs 15?
- **Test with different signing**: Development vs Distribution certificates
- **Share your findings**: Open GitHub Issues with your test results

### **If You're an SMAppService Expert**
- **Explain Error 108**: What does "Unable to read plist" actually indicate?
- **Debug our bundle**: Is there something wrong with our structure we're missing?
- **System-level debugging**: What logs or tools can help diagnose this?

### **If You Work at Apple**
- **Clarify SMAppService requirements**: What's needed for macOS 15?
- **Document Error 108**: What does this error code actually mean?
- **Provide working examples**: Official sample code would help immensely

## 🧪 **Test Our Implementation**

### **Prerequisites**
- macOS 15 Sequoia (issue may be specific to this version)
- Xcode 16.x
- Apple Developer account

### **Steps to Reproduce**
1. **Clone this repository**
2. **Open helperpoc.xcodeproj**
3. **Configure code signing** with your development team
4. **Build and run** (works perfectly)
5. **Click "Register Helper"** → Error 108 "Unable to read plist"

### **What You Should See**
- ✅ **Perfect build and launch**: Demonstrates our implementation works
- ✅ **Proper bundle structure**: Check the built .app bundle
- ✅ **Clean code signing**: No signing errors
- ❌ **Registration failure**: Error 108 when attempting helper registration

## 📈 **Our Progress**

### **✅ Completely Solved**
- **Build system**: Xcode project creates perfect bundle structure
- **Helper embedding**: Copy Files build phases work correctly
- **Code signing**: Both development and distribution signing clean
- **Bundle validation**: All files in correct locations with valid format
- **Development workflow**: Can build and test reliably

### **❌ Still Blocked**
- **SMAppService registration**: Error 108 persists
- **Root cause unknown**: Don't understand what's actually wrong
- **No working examples**: Can't compare against known-good implementations

## 💡 **Key Insights for Debugging**

### **What We've Eliminated**
1. **Build system issues**: Xcode project creates correct structure
2. **Bundle structure problems**: Files are in expected locations
3. **Plist format errors**: Passes validation, correct BundleProgram format
4. **Basic code signing**: Certificates and signatures are valid
5. **Development workflow**: Can reliably reproduce the issue

### **What Still Needs Investigation**
1. **System-level permissions**: Can SMAppService access bundle contents?
2. **macOS 15 behavioral changes**: Are there new requirements?
3. **Sandboxing interactions**: Does helper sandboxing affect main app registration?
4. **Undocumented requirements**: Missing configuration we don't know about?

## 🤝 **Community Collaboration**

### **GitHub**
- **Issues**: Report your SMAppService experiences and test results
- **Discussions**: Collaborate on debugging approaches and theories
- **Pull Requests**: Improvements to our implementation or documentation

### **Apple Channels**  
- **Feedback Assistant**: File reports about Error 108 (include our reproduction case)
- **Developer Forums**: Post in Service Management tag with specific technical questions
- **Developer Support**: Submit Technical Support Incidents for official guidance

### **Research Areas**
- **System logs analysis**: What happens at the OS level during Error 108?
- **Bundle comparison**: Working vs non-working SMAppService bundles
- **macOS version testing**: Does this work on older macOS versions?
- **Alternative configurations**: Different plist formats, entitlements, etc.

---

## 🎯 **Summary: Complete Implementation, Unknown Root Cause**

We have a **production-ready SMAppService implementation** that demonstrates a specific, reproducible issue:

1. **✅ Technical implementation**: Complete and follows all documented requirements
2. **✅ Build system**: Proper Xcode project with correct bundle creation
3. **✅ Reproducible issue**: Anyone can verify the same Error 108
4. **❌ Unknown root cause**: Don't understand why "Unable to read plist" occurs

**This is not a build system problem - everything works except SMAppService registration.**

The Error 108 "Unable to read plist" suggests SMAppService cannot access or parse the helper daemon's plist file, but we don't know why. The file exists, is valid, and is in the documented location.

**We need community help to understand what's actually wrong and how to fix it! 🙏**

---

*Last Updated: January 2025 - Complete implementation with reproducible Error 108 issue*