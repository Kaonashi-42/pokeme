// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PokeMe",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure, EventKit-free logic: everything worth unit testing lives here.
        .target(name: "PokeMeCore"),
        // The menu bar app: EventKit, AppKit and SwiftUI glue.
        .executableTarget(name: "PokeMe", dependencies: ["PokeMeCore"]),
        .testTarget(name: "PokeMeCoreTests", dependencies: ["PokeMeCore"]),
    ]
)
