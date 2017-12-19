// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "sf-beverage",
    products: [
        .library(name: "XCalendar", targets: ["XCalendar"]),
        .executable(name: "SFBeverage", targets: ["SFBeverage"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.2.0")),
        .package(url: "https://github.com/vapor/leaf-provider.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(name: "XCalendar", dependencies: []),
        .target(name: "SFBeverage", dependencies: ["Vapor", "LeafProvider", "XCalendar"]),
    ]
)

