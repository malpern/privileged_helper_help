import Foundation
import os.log

class FileLogger {
    static let shared = FileLogger()
    
    private let logDirectory: URL
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    
    private init() {
        // Create logs directory in /tmp for easy access
        logDirectory = URL(fileURLWithPath: "/tmp")
        logFileURL = logDirectory.appendingPathComponent("helperpoc-app.log")
        
        // Create logs directory if it doesn't exist
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // Create or open log file
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
        
        // Log startup
        log("=== HelperPOC App Started ===")
        log("Log file: \(logFileURL.path)")
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    func log(_ message: String, level: String = "INFO") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] [\(level)] [APP] \(message)\n"
        
        // Write to file
        if let data = logLine.data(using: .utf8) {
            fileHandle?.write(data)
        }
        
        // Also print to console for immediate visibility
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