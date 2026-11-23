package io.meshtrax.traxpix_litert

import io.flutter.embedding.engine.plugins.FlutterPlugin

// Only registers the plugin: Dart reaches LiteRT through FFI, in the
// libLiteRt.so this module adds to the app.
class TraxpixLitertPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
