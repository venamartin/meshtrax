package com.meshtrax.app

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.view.WindowInsets
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val usbFunctions by lazy { MeshTraxUsbFunctions(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbFunctions.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meshtrax/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manufacturer" -> result.success(Build.MANUFACTURER.lowercase())
                    "isBackgroundRestricted" -> result.success(isBackgroundRestricted())
                    "imeState" -> result.success(imeState())
                    else -> result.notImplemented()
                }
            }
    }

    private fun imeState(): Map<String, Any>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val insets = window.decorView.rootWindowInsets ?: return null
        return mapOf(
            "visible" to insets.isVisible(WindowInsets.Type.ime()),
            "bottomPx" to insets.getInsets(WindowInsets.Type.ime()).bottom,
        )
    }

    private fun isBackgroundRestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return activityManager.isBackgroundRestricted
    }

    override fun onDestroy() {
        usbFunctions.dispose()
        super.onDestroy()
    }
}
