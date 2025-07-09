// Main application entry point - creates the SwiftUI app that demonstrates
// the SMAppService registration failure on macOS 15 beta

import SwiftUI

struct HelperPOCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

HelperPOCApp.main()