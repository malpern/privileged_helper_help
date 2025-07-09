import Foundation
import os.log

class HelperFileLogger {
    static let shared = HelperFileLogger()
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    
    private init() {
        // Log to /tmp for helper daemon (runs as root)
        logFileURL = URL(fileURLWithPath: "/tmp/helperpoc-daemon.log")
        
        // Create or open log file
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
        
        // Log startup
        log("=== HelperPOC Daemon Started ===")
        log("Log file: \(logFileURL.path)")
        log("Running as UID: \(getuid()), EUID: \(geteuid())")
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    func log(_ message: String, level: String = "INFO") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] [\(level)] [DAEMON] \(message)\n"
        
        // Write to file
        if let data = logLine.data(using: .utf8) {
            fileHandle?.write(data)
            fileHandle?.synchronizeFile() // Force write to disk
        }
        
        // Also print to console
        print(logLine.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func logError(_ message: String) {
        log(message, level: "ERROR")
    }
    
    func logDebug(_ message: String) {
        log(message, level: "DEBUG")
    }
    
    var logFilePath: String {
        return logFileURL.path
    }
}