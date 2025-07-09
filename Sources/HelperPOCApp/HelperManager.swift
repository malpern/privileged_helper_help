// SMAppService management class - handles registration and communication with the privileged helper
// This is where the "Unable to read plist" error occurs on macOS 15 beta

import Foundation
import ServiceManagement
import os.log

@MainActor
class HelperManager: ObservableObject {
    private let helperPlistName = "com.keypath.helperpoc"
    private let helperMachServiceName = "com.keypath.helperpoc.xpc"
    private let logger = Logger(subsystem: "com.keypath.helperpoc", category: "HelperManager")
    
    @Published var isHelperRegistered = false
    @Published var status: SMAppService.Status = .notRegistered
    
    private var xpcConnection: NSXPCConnection?
    
    func checkStatus() {
        let service = SMAppService.daemon(plistName: helperPlistName)
        status = service.status
        isHelperRegistered = (status == .enabled)
        let statusMsg = "Helper status: \(String(describing: self.status))"
        logger.info("\(statusMsg)")
        FileLogger.shared.log(statusMsg)
    }
    
    func registerHelper() async throws {
        let service = SMAppService.daemon(plistName: helperPlistName)
        
        FileLogger.shared.log("Attempting to register helper...")
        logger.info("Attempting to register helper...")
        
        do {
            try service.register()
            FileLogger.shared.log("Helper registration initiated")
            logger.info("Helper registration initiated")
            
            // Wait briefly for registration to complete
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            checkStatus()
            
            if status == .requiresApproval {
                let msg = "Helper requires user approval in System Settings"
                FileLogger.shared.log(msg)
                logger.info("\(msg)")
                throw HelperError.requiresApproval
            }
            
        } catch {
            let msg = "Helper registration failed: \(error.localizedDescription)"
            FileLogger.shared.logError(msg)
            logger.error("\(msg)")
            throw error
        }
    }
    
    func unregisterHelper() async throws {
        let service = SMAppService.daemon(plistName: helperPlistName)
        
        logger.info("Attempting to unregister helper...")
        
        // Close any existing connection
        xpcConnection?.invalidate()
        xpcConnection = nil
        
        do {
            try await service.unregister()
            logger.info("Helper unregistered successfully")
            checkStatus()
        } catch {
            logger.error("Helper unregistration failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func testHelper() async throws -> String {
        guard isHelperRegistered else {
            FileLogger.shared.logError("Helper not registered")
            throw HelperError.notRegistered
        }
        
        FileLogger.shared.log("Starting helper test...")
        let connection = getXPCConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let remoteProxy = connection.remoteObjectProxyWithErrorHandler { error in
                let msg = "XPC connection error: \(error.localizedDescription)"
                FileLogger.shared.logError(msg)
                self.logger.error("\(msg)")
                continuation.resume(throwing: error)
            } as! HelperProtocol
            
            remoteProxy.createTestFile { success, message in
                if success {
                    let result = message ?? "Test completed successfully"
                    FileLogger.shared.log("Helper test successful: \(result)")
                    continuation.resume(returning: result)
                } else {
                    let error = message ?? "Unknown error"
                    FileLogger.shared.logError("Helper test failed: \(error)")
                    continuation.resume(throwing: HelperError.testFailed(error))
                }
            }
        }
    }
    
    private func getXPCConnection() -> NSXPCConnection {
        if let connection = xpcConnection {
            return connection
        }
        
        let connection = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        
        connection.invalidationHandler = {
            self.logger.info("XPC connection invalidated")
            self.xpcConnection = nil
        }
        
        connection.interruptionHandler = {
            self.logger.info("XPC connection interrupted")
        }
        
        connection.resume()
        xpcConnection = connection
        
        return connection
    }
}

enum HelperError: LocalizedError {
    case notRegistered
    case requiresApproval
    case testFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notRegistered:
            return "Helper is not registered"
        case .requiresApproval:
            return "Helper requires user approval in System Settings > General > Login Items"
        case .testFailed(let message):
            return "Helper test failed: \(message)"
        }
    }
}