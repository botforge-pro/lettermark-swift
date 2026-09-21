// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Lettermark",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],
  products: [
    .library(
      name: "Lettermark",
      targets: ["Lettermark"])
  ],
  dependencies: [
    .package(url: "https://github.com/botforge-pro/swift-embed", from: "1.5.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.3.0"),
  ],
  targets: [
    .target(name: "Lettermark"),
    .testTarget(
      name: "LettermarkTests",
      dependencies: [
        "Lettermark",
        .product(name: "SwiftEmbed", package: "swift-embed"),
      ],
      resources: [.process("Resources")]),
  ]
)
