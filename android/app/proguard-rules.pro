# ML Kit creates its component registrars by reflection. Since AGP 9, keeping a
# class no longer keeps its no-argument constructor, and without it the barcode
# reader is never registered: QR scanning fails in release builds.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
