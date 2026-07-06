// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TomatoReminder",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TomatoReminder", targets: ["TomatoReminder"])
    ],
    targets: [
        .executableTarget(
            name: "TomatoReminder",
            path: "Sources/TomatoReminder"
        )
    ]
)
