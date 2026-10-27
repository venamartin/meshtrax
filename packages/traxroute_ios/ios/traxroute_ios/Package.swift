// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "traxroute_ios",
  platforms: [
    // valhalla-mobile's own minimum.
    .iOS("16.4")
  ],
  products: [
    .library(name: "traxroute-ios", targets: ["traxroute_ios"])
  ],
  dependencies: [
    // Valhalla 3.9.1, the version the routing tiles are built with.
    .package(url: "https://github.com/Rallista/valhalla-mobile.git", exact: "0.6.4")
  ],
  targets: [
    .target(
      name: "traxroute_ios",
      dependencies: [
        .product(name: "Valhalla", package: "valhalla-mobile")
      ]
    )
  ]
)
