pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // Explicit KGP: AGP 9's built-in Kotlin is 2.2.10, below Flutter's minimum
    // (flutter/flutter#192167). Drop this for android.builtInKotlin=true once
    // AGP bundles Kotlin >= Flutter's floor.
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
