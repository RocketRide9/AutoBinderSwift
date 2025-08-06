// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let collections = Target.Dependency.product(
    name: "Collections",
    package: "swift-collections"
)

let package = Package(
    name: "AutoBinder",
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git", 
            .upToNextMinor(from: "1.2.0") // or `.upToNextMajor
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "AutoBinder",
            dependencies: ["Vala", "Guides", "Strings"],
            path: "Sources/AutoBinder"),
        .target(
            name: "Vala",
            dependencies: ["Strings", "KhronosRegistry"],
            path: "Sources/Vala",),
        .target(
            name: "KhronosRegistry",
            dependencies: [
                "Extensions",
                collections
            ],
            path: "Sources/KhronosRegistry"),
        .target(
            name: "Extensions",
            path: "Sources/Extensions"),
        .target(
            name: "Guides",
            path: "Sources/Guides"),
        .target(
            name: "Strings",
            path: "Sources/Strings")
    ],
)
