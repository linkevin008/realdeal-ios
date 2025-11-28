// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RealDeal",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RealDeal",
            targets: ["RealDeal"])
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "RealDeal",
            dependencies: [],
            path: "RealDeal",
            exclude: ["RealDealApp.swift", "ContentView.swift", "Info.plist", "Assets.xcassets"],
            resources: [.process("RealDeal.xcdatamodeld")]),
        .testTarget(
            name: "RealDealTests",
            dependencies: [
                "RealDeal",
                .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "RealDealTests")
    ]
)
