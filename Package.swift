// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "users",
    products: [
        .library(name: "App", targets: ["App"]),
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
       .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.0.0")),
        // .package(url: "https://github.com/vapor/crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor-community/sendgrid-provider.git", from: "3.0.6"),
        .package(url: "https://github.com/vapor-community/lingo-vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/skelpo/JWTDataProvider.git", from: "1.0.0"),
        .package(url: "https://github.com/skelpo/JWTVapor.git", from: "0.13.0"),
        .package(url: "https://github.com/skelpo/SkelpoMiddleware.git", from: "1.4.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentMySQL", "JWT", "CryptoSwift", "SendGrid", "LingoVapor", "JWTDataProvider", "JWTVapor", "SkelpoMiddleware"],
                exclude: [
                    "Config",
                    "Public",
                    "Resources",
                    ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
