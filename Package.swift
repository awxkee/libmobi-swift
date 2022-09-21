// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "libmobi",
    products: [
        .library(
            name: "libmobi",
            type: .dynamic,
            targets: ["libmobi"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "libmobi",
            dependencies: ["libmobic"]),
        .target(name: "libmobic",
                publicHeadersPath: "include",
                cSettings: [.define("HAVE_CONFIG_H"), .define("HAVE_STRDUP"), .define("USE_XMLWRITER")],
                linkerSettings: [
                    .linkedLibrary("z")
                ]),
    ]
)
