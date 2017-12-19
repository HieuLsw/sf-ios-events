// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "sf-beverage",
    products: [
        .library(name: "App", targets: ["App"]),
        .library(name: "XCalendar", targets: ["XCalendar"]),
        .executable(name: "SFBeverage", targets: ["SFBeverage"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.2.0")),
        .package(url: "https://github.com/vapor/leaf-provider.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(name: "XCalendar", dependencies: []),
        .target(name: "App", dependencies: ["Vapor", "LeafProvider"],
               exclude: [
                   "Config",
                   "Database",
                   "Public",
                   "Resources"
               ]),
        .target(name: "SFBeverage", dependencies: ["App", "Vapor", "LeafProvider", "XCalendar"]),
        .testTarget(name: "AppTests", dependencies: ["App", "Testing"])
    ]
)

