// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "traxpix_litert",
  platforms: [
    .iOS("16.0")
  ],
  products: [
    // The Flutter tooling requires the dasherized plugin name.
    .library(name: "traxpix-litert", targets: ["traxpix_litert"])
  ],
  dependencies: [],
  targets: [
    // Only registers the plugin. Dart reaches LiteRT through FFI, in the
    // CLiteRT framework this target links and the app embeds.
    .target(
      name: "traxpix_litert",
      dependencies: ["CLiteRT"]
    ),
    // LiteRT 2.3.0's C API for iPhones and the simulator, as Google
    // publishes it, from MeshTrax's host, pinned by its SHA-256.
    .binaryTarget(
      name: "CLiteRT",
      url: "https://maps.meshtrax.io/runtimes/litert-2.3.0/b36a1a4f1b3eeb04546b4cc2986902cd704439b37c34597ab0f804aed08f5a00/CLiteRT.xcframework.zip",
      checksum: "b36a1a4f1b3eeb04546b4cc2986902cd704439b37c34597ab0f804aed08f5a00"
    )
  ]
)
