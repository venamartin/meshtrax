// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "traxpix_litert",
  platforms: [
    .macOS("12.0")
  ],
  products: [
    // The Flutter tooling requires the dasherized plugin name.
    .library(name: "traxpix-litert", targets: ["traxpix_litert"])
  ],
  dependencies: [],
  targets: [
    // Only registers the plugin. Dart reaches LiteRT through FFI, in the
    // CLiteRT_mac library this target links and the app embeds.
    .target(
      name: "traxpix_litert",
      dependencies: ["CLiteRT_mac"]
    ),
    // LiteRT 2.3.0's C API for Macs (Apple silicon and Intel), as Google
    // publishes it, from MeshTrax's host, pinned by its SHA-256.
    .binaryTarget(
      name: "CLiteRT_mac",
      url: "https://maps.meshtrax.io/runtimes/litert-2.3.0/071b9f4bebb483709ac3d7faf98123da5453a2ebf60ce8f819aa1e30b9535a98/CLiteRT_mac.xcframework.zip",
      checksum: "071b9f4bebb483709ac3d7faf98123da5453a2ebf60ce8f819aa1e30b9535a98"
    )
  ]
)
