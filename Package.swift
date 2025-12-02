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
            exclude: [
                "Info.plist",
                "RealDeal.swift",
                "RealDeal.entitlements",
                "README.md",
                "Services/FilterService_README.md",
                "Services/ExternalListingAPI_README.md",
                "Services/AI_SERVICES_README.md",
                "Utilities/CoreData/README.md",
                "Utilities/CoreData/MIGRATION_STRATEGY.md",
                "Utilities/IMAGE_HANDLING_README.md",
                "Utilities/ERROR_HANDLING_README.md",
                "Navigation/README.md"
            ],
            resources: [
                .process("RealDeal.xcdatamodeld"),
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("CoreData"),
                .linkedFramework("MapKit"),
                .linkedFramework("Combine")
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
