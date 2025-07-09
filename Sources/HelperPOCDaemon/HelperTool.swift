import Foundation
import os.log

class HelperTool: NSObject, HelperProtocol {
    private let logger = Logger(subsystem: "com.keypath.helperpoc", category: "HelperTool")
    
    func createTestFile(reply: @escaping (Bool, String?) -> Void) {
        HelperFileLogger.shared.log("Creating test file...")
        logger.info("Creating test file...")
        
        let testFilePath = "/tmp/helper_test_\(Date().timeIntervalSince1970).txt"
        let testContent = "Hello from privileged helper! Created at \(Date())"
        
        do {
            try testContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)
            
            // Set root ownership to prove we have privileges
            let result = chown(testFilePath, 0, 0) // uid: 0 (root), gid: 0 (wheel)
            
            if result == 0 {
                let msg = "Test file created successfully at \(testFilePath)"
                HelperFileLogger.shared.log(msg)
                logger.info("\(msg)")
                reply(true, "Test file created at \(testFilePath) with root ownership")
            } else {
                let msg = "Failed to set root ownership on test file"
                HelperFileLogger.shared.logError(msg)
                logger.error("\(msg)")
                reply(false, "Test file created but failed to set root ownership")
            }
            
        } catch {
            let msg = "Failed to create test file: \(error.localizedDescription)"
            HelperFileLogger.shared.logError(msg)
            logger.error("\(msg)")
            reply(false, msg)
        }
    }
    
    func getHelperInfo(reply: @escaping (Bool, String?) -> Void) {
        logger.info("Getting helper info...")
        
        let uid = getuid()
        let euid = geteuid()
        let gid = getgid()
        let egid = getegid()
        
        let info = """
        Helper Process Info:
        - UID: \(uid)
        - EUID: \(euid)
        - GID: \(gid)
        - EGID: \(egid)
        - Running as root: \(euid == 0)
        - Process ID: \(getpid())
        """
        
        logger.info("Helper info: \(info)")
        reply(true, info)
    }
}