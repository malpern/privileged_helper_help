# Xcode Project Setup Guide

## Step 1: Replace ContentView.swift in Main App

1. **In Xcode**: Click on `ContentView.swift` under the `helperpoc` target
2. **Select all content** (Cmd+A) and **delete it**
3. **Copy-paste this code**:

```swift
// Main UI view - provides buttons to test SMAppService registration
// and displays the persistent "Unable to read plist" error

import SwiftUI
import ServiceManagement

struct ContentView: View {
    @StateObject private var helperManager = HelperManager()
    @State private var statusMessage = "Helper not registered"
    @State private var testResult = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SMAppService Privileged Helper POC")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Helper Status: \(statusMessage)")
                    .foregroundColor(helperManager.isHelperRegistered ? .green : .red)
                
                if !helperManager.isHelperRegistered {
                    Button("Register Helper") {
                        Task {
                            await registerHelper()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if helperManager.isHelperRegistered {
                    Button("Test Helper") {
                        Task {
                            await testHelper()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Unregister Helper") {
                        Task {
                            await unregisterHelper()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if !testResult.isEmpty {
                Text("Test Result:")
                    .font(.headline)
                Text(testResult)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            checkHelperStatus()
        }
    }
    
    private func checkHelperStatus() {
        helperManager.checkStatus()
        updateStatusMessage()
    }
    
    private func updateStatusMessage() {
        switch helperManager.status {
        case .notRegistered:
            statusMessage = "Not registered"
        case .enabled:
            statusMessage = "Enabled"
        case .requiresApproval:
            statusMessage = "Requires user approval"
        case .notFound:
            statusMessage = "Not found"
        @unknown default:
            statusMessage = "Unknown status"
        }
    }
    
    private func registerHelper() async {
        do {
            try await helperManager.registerHelper()
            checkHelperStatus()
        } catch {
            testResult = "Registration failed: \(error.localizedDescription)"
        }
    }
    
    private func testHelper() async {
        do {
            let result = try await helperManager.testHelper()
            testResult = "Helper test successful: \(result)"
        } catch {
            testResult = "Helper test failed: \(error.localizedDescription)"
        }
    }
    
    private func unregisterHelper() async {
        do {
            try await helperManager.unregisterHelper()
            checkHelperStatus()
            testResult = "Helper unregistered successfully"
        } catch {
            testResult = "Unregistration failed: \(error.localizedDescription)"
        }
    }
}
```

## Step 2: Add Missing Swift Files to Main App

**Right-click on the `helperpoc` folder** in Xcode and select **"New File"** for each of these:

### HelperManager.swift
```swift
// [Content will be provided next]
```

### HelperProtocol.swift  
```swift
// [Content will be provided next]
```

### FileLogger.swift
```swift
// [Content will be provided next]
```

## Step 3: Setup Helper Target

### Replace main.swift in helperpoc-helper target
```swift
// [Content will be provided next]
```

## Step 4: Add Build Phases

[Instructions for build phases will be added]

---

**Note**: This guide will be completed step by step. Start with Step 1 and let me know when you're ready for the next files!
```