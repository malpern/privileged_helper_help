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