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
            exclude: ["Info.plist", "RealDealApp.swift"],
            resources: [
                .process("RealDeal.xcdatamodeld"),
                .process("Assets.xcassets")
            ]),
        .testTarget(
            name: "RealDealTests",
            dependencies: [
                "RealDeal",
                .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "RealDealTests")
    ]
)
