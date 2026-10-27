package com.meshtrax.app

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val usbFunctions by lazy { MeshTraxUsbFunctions(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        resyncInsetsAfterKeyboardAnimations()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbFunctions.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meshtrax/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manufacturer" -> result.success(Build.MANUFACTURER.lowercase())
                    "isBackgroundRestricted" -> result.success(isBackgroundRestricted())
                    else -> result.notImplemented()
                }
            }
    }

    // When a keyboard animation ends, Flutter re-sends the insets saved during
    // the last animation that saved any (ImeSyncDeferringInsetsCallback.onEnd),
    // even when they are stale. After a resume that can be a keyboard that is
    // no longer up, leaving a keyboard-sized gap. Asking Android for the
    // current insets after each keyboard animation overwrites that copy.
    private fun resyncInsetsAfterKeyboardAnimations() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val content = findViewById<View>(android.R.id.content)
        content.setWindowInsetsAnimationCallback(
            object : WindowInsetsAnimation.Callback(
                WindowInsetsAnimation.Callback.DISPATCH_MODE_CONTINUE_ON_SUBTREE,
            ) {
                override fun onProgress(
                    insets: WindowInsets,
                    runningAnimations: List<WindowInsetsAnimation>,
                ) = insets

                override fun onEnd(animation: WindowInsetsAnimation) {
                    if ((animation.typeMask and WindowInsets.Type.ime()) != 0) {
                        content.requestApplyInsets()
                    }
                }
            },
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
