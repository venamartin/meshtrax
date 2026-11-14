package com.meshtrax.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
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
    private val routing = MeshTraxRouting()
    private val drive by lazy { MeshTraxDrive(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        resyncInsetsAfterKeyboardAnimations()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbFunctions.configureFlutterEngine(flutterEngine)
        routing.configureFlutterEngine(flutterEngine)
        drive.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meshtrax/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manufacturer" -> result.success(Build.MANUFACTURER.lowercase())
                    "isBackgroundRestricted" -> result.success(isBackgroundRestricted())
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // The notification settings page takes this extra from API 26. Older
    // Android, or a device without the page, gets the app's own settings page.
    private fun openNotificationSettings() {
        val appDetails = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            startActivity(appDetails)
            return
        }
        try {
            startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
            )
        } catch (e: ActivityNotFoundException) {
            startActivity(appDetails)
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

    // The drive folder picker answers here; anything else goes on to the plugins.
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!drive.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        usbFunctions.dispose()
        routing.dispose()
        drive.dispose()
        super.onDestroy()
    }
}
