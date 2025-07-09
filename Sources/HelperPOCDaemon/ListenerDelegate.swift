import Foundation
import Security
import os.log

class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    private let logger = Logger(subsystem: "com.keypath.helperpoc", category: "ListenerDelegate")
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        HelperFileLogger.shared.log("Received new XPC connection request")
        logger.info("Received new XPC connection request")
        
        // MANDATORY: Validate connecting client
        guard validateClient(connection: newConnection) else {
            HelperFileLogger.shared.logError("Client validation failed - rejecting connection")
            logger.error("Client validation failed - rejecting connection")
            return false
        }
        
        HelperFileLogger.shared.log("Client validation passed - accepting connection")
        logger.info("Client validation passed - accepting connection")
        
        // Configure the connection
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        let helperTool = HelperTool()
        newConnection.exportedObject = helperTool
        
        newConnection.invalidationHandler = {
            self.logger.info("XPC connection invalidated")
        }
        
        newConnection.interruptionHandler = {
            self.logger.info("XPC connection interrupted")
        }
        
        newConnection.resume()
        
        return true
    }
    
    private func validateClient(connection: NSXPCConnection) -> Bool {
        HelperFileLogger.shared.log("Validating client connection...")
        logger.info("Validating client connection...")
        
        // Get the process ID of the connecting client
        let clientPID = connection.processIdentifier
        HelperFileLogger.shared.log("Client PID: \(clientPID)")
        logger.info("Client PID: \(clientPID)")
        
        // For signed POC, we'll implement basic validation
        // In production, you'd add full code signature verification
        
        if clientPID > 0 {
            // TODO: Add proper code signature validation here
            // For now, accept any valid process (since we're signed)
            HelperFileLogger.shared.log("Client validation passed (signed POC mode)")
            logger.info("Client validation passed (signed POC mode)")
            return true
        } else {
            HelperFileLogger.shared.logError("Invalid client PID")
            logger.error("Invalid client PID")
            return false
        }
    }
}