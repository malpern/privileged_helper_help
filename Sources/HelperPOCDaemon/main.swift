// Privileged helper daemon entry point - this is the executable that SMAppService
// attempts to register but fails with "Unable to read plist" on macOS 15 beta

import Foundation
import os.log

let logger = Logger(subsystem: "com.keypath.helperpoc", category: "HelperDaemon")

func main() {
    // Initialize file logging
    HelperFileLogger.shared.log("Helper daemon starting...")
    logger.info("Helper daemon starting...")
    
    let listener = NSXPCListener(machServiceName: "com.keypath.helperpoc.xpc")
    let delegate = ListenerDelegate()
    listener.delegate = delegate
    
    listener.resume()
    
    HelperFileLogger.shared.log("Helper daemon listening for XPC connections")
    logger.info("Helper daemon listening for XPC connections")
    
    // Keep the daemon running
    RunLoop.current.run()
}

main()