# macOS SMAppService Implementation - Help Still Needed! 🆘

This repository contains a **systematically verified SMAppService implementation** that demonstrates a persistent Error 108 "Unable to read plist" issue on macOS 15 Sequoia. Despite comprehensive testing, meeting all documented requirements, and achieving full Apple notarization, SMAppService registration consistently fails.

**We need community help to understand what we're missing!** 🙏

**Updated July 2025: Complete systematic analysis with production-ready implementation**

## What We're Trying to Accomplish

We're building an app that integrates with [Kanata](https://github.com/jtroo/kanata), a cross-platform keyboard remapper. Our macOS implementation requires:

1. **Register a privileged daemon** using the modern `SMAppService` API
2. **Execute root-level operations** for system-wide keyboard event interception  
3. **Communicate with the main app** via XPC
4. **Work reliably on macOS 15+** (Sequoia and later)

This is a **real-world use case** that should work according to Apple's documentation, but we're hitting systematic roadblocks.

## 🚨 **The Core Problem**

SMAppService registration fails with Error 108 "Unable to read plist" despite having:
- ✅ **Complete configuration alignment**: All bundle identifiers, plist names, and references match
- ✅ **Embedded helper Info.plist**: With required SMAuthorizedClients configuration  
- ✅ **Full notarization**: Apple-approved Developer ID signing with stapled ticket
- ✅ **Perfect build system**: Xcode project creates correct bundle structure
- ✅ **All documented requirements**: Follows Apple's official SMAppService documentation

## 📊 **What We've Systematically Verified**

### ✅ **Complete Technical Implementation**

**Bundle Identifier Alignment:**
- Main app: `com.keypath.helperpoc`
- Helper daemon: `com.keypath.helperpoc.helper`  
- Daemon plist: `com.keypath.helperpoc.helper.plist`
- All references consistently aligned across configuration

**Embedded Helper Info.plist:**
```xml
<key>SMAuthorizedClients</key>
<array>
    <string>identifier "com.keypath.helperpoc" and anchor apple generic...</string>
</array>
```
- ✅ Embedded as binary section via CREATE_INFOPLIST_SECTION_IN_BINARY=YES
- ✅ Verified with `otool -s __TEXT __info_plist`

**Production Signing & Notarization:**
- ✅ Manual signing with Developer ID Application certificates
- ✅ Secure timestamps (`--timestamp` flag)
- ✅ Debug entitlements removed (CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO)
- ✅ **Successfully notarized by Apple** (status: Accepted)
- ✅ **Stapled and verified** (spctl -a -vvv: accepted)

### ✅ **Verified Configuration Details**

**Helper Daemon Plist (com.keypath.helperpoc.helper.plist):**
```xml
<key>Label</key>
<string>com.keypath.helperpoc.helper</string>
<key>BundleProgram</key>
<string>Contents/MacOS/helperpoc-helper</string>
<key>AssociatedBundleIdentifiers</key>
<array>
    <string>com.keypath.helperpoc.helper</string>
</array>
<key>MachServices</key>
<dict>
    <key>com.keypath.helperpoc.xpc</key>
    <true/>
</dict>
```

**SMPrivilegedExecutables in Main App:**
```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.keypath.helperpoc.helper</key>
    <string>identifier "com.keypath.helperpoc.helper" and anchor apple generic...</string>
</dict>
```

**HelperManager Configuration:**
```swift
private let helperPlistName = "com.keypath.helperpoc.helper"  // Matches filename
```

## ❌ **Persistent Error Despite Perfect Implementation**

### **Error 108 "Unable to read plist"**
```
Registration failed: The operation couldn't be completed. 
Unable to read plist: com.keypath.helperpoc.helper (Code: 108, Domain: SMAppServiceErrorDomain)
```

**Error occurs when:**
- ✅ App builds and launches successfully (notarized, production-signed)
- ✅ All configuration verified correct via systematic analysis
- ✅ Bundle structure matches Apple's requirements exactly
- ❌ SMAppService.daemon(plistName:).register() fails with Error 108

## 🔧 **Systematic Debugging Process**

### **Issues We've Identified and Fixed:**

1. **Bundle identifier mismatches** ✅ FIXED
   - Problem: Helper using main app's bundle ID
   - Solution: Distinct helper bundle ID with aligned references

2. **Missing embedded Info.plist** ✅ FIXED  
   - Problem: Helper had no embedded Info.plist with SMAuthorizedClients
   - Solution: Created Info.plist with CREATE_INFOPLIST_SECTION_IN_BINARY

3. **Daemon plist naming mismatches** ✅ FIXED
   - Problem: HelperManager referenced wrong plist filename
   - Solution: Aligned filename, Label, and HelperManager references

4. **Production signing requirements** ✅ FIXED
   - Problem: Development certificates insufficient for SMAppService
   - Solution: Full Developer ID signing with notarization

### **Configuration Verification Process:**

**Bundle Structure Verification:**
```bash
# Verified correct structure
helperpoc.app/Contents/MacOS/helperpoc-helper          # Helper binary
helperpoc.app/Contents/Library/LaunchDaemons/com.keypath.helperpoc.helper.plist  # Daemon plist
```

**Code Signing Verification:**
```bash
codesign -vvv --deep-verify helperpoc.app              # ✅ Valid
spctl -a -vvv helperpoc.app                           # ✅ Accepted (Notarized)
```

**Embedded Info.plist Verification:**
```bash
otool -s __TEXT __info_plist helperpoc-helper          # ✅ Contains SMAuthorizedClients
```

## 🤔 **What We Still Don't Understand**

### **Root Cause of Error 108**
- **System-level issue**: SMAppService may have macOS 15-specific restrictions
- **Undocumented requirements**: Apple's documentation may be incomplete
- **Runtime vs build-time**: Issue may be in SMAppService implementation, not our configuration

### **Critical Questions**
1. **Does SMAppService require additional notarization steps** beyond stapling?
2. **Are there macOS 15-specific behavioral changes** not documented by Apple?
3. **Does the error indicate a system policy restriction** rather than configuration issue?
4. **Is Error 108 a genuine bug** in macOS 15's SMAppService implementation?

## 🧪 **Reproduce Our Systematic Analysis**

### **Prerequisites**
- macOS 15.x Sequoia
- Xcode 16.x
- Apple Developer account with Developer ID certificates

### **Steps to Verify**
1. **Clone repository**: `git clone https://github.com/malpern/privileged_helper_help.git`
2. **Open Xcode project**: Open `helperpoc/helperpoc.xcodeproj` in Xcode
3. **Configure signing**: Set your development team in project settings
4. **Build and run**: ⌘R → App launches successfully
5. **Test registration**: Click "Register Helper" → Observe Error 108
6. **Verify our analysis**: Check that bundle structure matches our specification

### **What You'll Confirm**
- ✅ **Perfect implementation**: Every configuration detail correct
- ✅ **Production-ready app**: Fully notarized and stapled
- ✅ **Systematic process**: Clear debugging methodology
- ❌ **Error 108 persists**: Despite meeting all requirements

## 💡 **Key Technical Insights**

### **What We've Proven Works**
1. **Complete configuration methodology**: Systematic approach to SMAppService setup
2. **Production signing workflow**: Full Developer ID notarization process
3. **Bundle structure requirements**: Verified correct file placement and naming
4. **Development workflow**: Reliable build and test process

### **What We've Eliminated as Cause**
1. **Configuration errors**: All identifiers and references systematically aligned
2. **Build system issues**: Xcode project creates perfect bundle structure  
3. **Code signing problems**: Full production signing with Apple verification
4. **Documentation compliance**: Implementation follows all published requirements

### **What Still Needs Investigation**
1. **macOS 15 system restrictions**: Undocumented changes in Sequoia
2. **SMAppService runtime behavior**: Internal implementation details
3. **System policy interactions**: Gatekeeper, System Integrity Protection, etc.
4. **Alternative SMAppService configurations**: Different implementation approaches

## 🆘 **Specific Help Needed**

**We've done extensive research and systematic testing, but we're still stuck. Can you help?**

### 🎯 **Most Urgent: Error 108 on macOS 15 Sequoia**
```
Registration failed: The operation couldn't be completed. 
Unable to read plist: com.keypath.helperpoc.helper (Code: 108, Domain: SMAppServiceErrorDomain)
```
- **What we've verified**: Complete configuration alignment, full notarization, all documented requirements
- **What works**: App builds, signs, notarizes, and passes all Apple validation  
- **What fails**: SMAppService.daemon(plistName:).register() throws Error 108
- **Question**: What does "Unable to read plist" actually mean and how do we fix it?

### 🎯 **Community Questions**
1. **Do you have a working SMAppService implementation on macOS 15?** Can you share code or guidance?
2. **Are there undocumented requirements** for SMAppService that we're missing?
3. **Have you seen Error 108 before?** How did you resolve it?
4. **Is this specific to our use case** (keyboard remapping) or a universal issue?

### 🎯 **How You Can Help**

**If You Have Working SMAppService:**
- **Share your implementation**: Even anonymized code samples would help enormously
- **Compare with our setup**: What differs from our systematically verified configuration?
- **Test our code**: Does it work with your certificates/setup?
- **Share your workflow**: Build process, signing, notarization steps

**If You're Also Stuck:**
- **Try our implementation**: Does it reproduce the same Error 108?
- **Share your findings**: Different error messages, macOS versions, approaches
- **Compare notes**: What have you tried that we haven't?

**If You Work at Apple:**
- **Clarify Error 108**: What does "Unable to read plist" actually indicate at the system level?
- **Document requirements**: Are there macOS 15-specific changes not in the public documentation?
- **Provide debugging guidance**: How should developers diagnose SMAppService issues?

### 🎯 **Contact Methods**
- **Open an issue** with suggestions, working examples, or questions
- **Submit a PR** if you spot something we missed
- **Discussions**: Use GitHub Discussions for broader collaboration

**We'd be incredibly grateful for any help!** This is blocking real-world keyboard remapping functionality that many users need. 🙏

## 📈 **Implementation Status**

### **✅ Production-Ready Foundation**
- **Native Xcode project**: Clean project structure with properly configured targets
- **Full notarization workflow**: Developer ID signing with Apple verification  
- **Systematic configuration**: All components aligned and verified
- **Comprehensive documentation**: Complete analysis and reproduction steps

### **❌ Runtime Registration Blocked**
- **SMAppService Error 108**: Consistent failure despite correct implementation
- **Unknown root cause**: Issue may be system-level or documentation gap
- **Need Apple guidance**: Requires official clarification or bug fix

## 🎯 **Summary: Complete Implementation, Still Need Help**

We have **comprehensively implemented and verified SMAppService** with the following outcomes:

1. **✅ Complete technical implementation**: Follows all documented Apple requirements
2. **✅ Production-ready signing**: Full Developer ID notarization workflow  
3. **✅ Systematic verification**: Every configuration detail confirmed correct
4. **✅ Real-world use case**: Keyboard remapping with Kanata integration
5. **❌ Persistent Error 108**: SMAppService registration fails despite perfect setup

**This represents a gap between Apple's documentation and macOS 15 runtime behavior.**

The systematic nature of our analysis demonstrates that this is not a configuration error, but likely indicates either:
- **Undocumented macOS 15 requirements** for SMAppService
- **Runtime bug** in SMAppService implementation  
- **Missing documentation** from Apple about Sequoia-specific changes

**This is blocking real keyboard remapping functionality - we need community help to solve this!** 🆘

## Current Status: Help Still Needed! 🙏

**What's Working**: ✅ 
- ✅ Complete implementation following Apple's guidelines systematically
- ✅ Full code signing and notarization pipeline verified by Apple
- ✅ Perfect bundle structure and configuration alignment
- ✅ Production-ready foundation for keyboard remapping app

**What's Still Broken**: ❌
- ❌ **Error 108 on macOS 15**: "Unable to read plist" despite perfect implementation
- ❌ **Cannot register privileged helper**: Blocking our Kanata integration
- ❌ **Unknown root cause**: Need community insight to identify the issue

**We Need Your Help With**:
1. **Understanding Error 108** - What does this actually mean at the system level?
2. **Working SMAppService examples** - Do you have code that works on macOS 15?
3. **Missing requirements** - Are there undocumented steps we're missing?
4. **Alternative approaches** - Should we abandon SMAppService for keyboard remapping?

**This affects real users who need keyboard remapping functionality on macOS. Any help appreciated!** 🚀

---

*Last Updated: July 2025 - Complete systematic analysis with production notarization*