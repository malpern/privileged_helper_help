// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PrivilegedHelperPOC",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "HelperPOCApp", targets: ["HelperPOCApp"]),
        .executable(name: "HelperPOCDaemon", targets: ["HelperPOCDaemon"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HelperPOCApp",
            dependencies: [],
            path: "Sources/HelperPOCApp"
        ),
        .executableTarget(
            name: "HelperPOCDaemon",
            dependencies: [],
            path: "Sources/HelperPOCDaemon"
        ),
    ]
)