// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DocCHooks",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v13),
    .watchOS(.v7),
    .visionOS(.v1)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "DocCHooks",
      targets: ["DocCHooks"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ra1028/swiftui-hooks", branch: "main"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
//    .package(url: "https://github.com/FullStack-Swift/swift-networking", branch: "main"),
//    .package(url: "https://github.com/realm/realm-swift", exact: "10.43.1"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DocCHooks",
      dependencies: [
        .product(name: "Hooks", package: "swiftui-hooks"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
//        .product(name: "CombineRequest", package: "swift-networking"),
//        .product(name: "CombineWebSocket", package: "swift-networking"),
//        .product(name: "RealmSwift", package: "realm-swift"),
        .product(name: "CasePaths", package: "swift-case-paths"),
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "DocCHooksTests",
      dependencies: [
        "DocCHooks",
        .product(name: "Hooks", package: "swiftui-hooks"),
      ]
    ),
  ]
)
