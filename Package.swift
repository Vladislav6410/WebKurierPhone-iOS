// swift-tools-version: 5.9
import PackageDescription

// Platform-independent pilot state and service contracts; no production networking.
let package = Package(
    name: "WebKurierPilot",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "PilotCore", targets: ["PilotCore"])],
    targets: [
        .target(name: "PilotCore", path: "App/PilotCore"),
        .testTarget(name: "PilotCoreTests", dependencies: ["PilotCore"], path: "Tests/PilotCoreTests")
    ]
)
