package com.meshtrax.app

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.provider.Settings
import android.app.ActivityManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.StatFs
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
                    "openNotificationChannelSettings" -> {
                        openNotificationChannelSettings(call.argument<String>("channelId"))
                        result.success(null)
                    }
                    "getAlarmVolume" -> result.success(alarmVolume())
                    "openSoundSettings" -> {
                        openSoundSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // "meshtrax/storage": freeBytes(path), the bytes free for a download
        // the user asks for (the photo model), and saveToPhotos(png), a photo
        // the user saves. iOS and macOS answer freeBytes too.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meshtrax/storage")
            .setMethodCallHandler { call, result ->
                val path = call.arguments as? String
                val png = call.arguments as? ByteArray
                if (call.method == "freeBytes" && path != null) {
                    result.success(freeBytes(path))
                } else if (call.method == "saveToPhotos" && png != null) {
                    result.success(saveToPhotos(png))
                } else {
                    result.notImplemented()
                }
            }
    }

    // A PNG into Pictures/MeshTrax through MediaStore, which needs no
    // permission on Android 10 and later. False when it couldn't be saved.
    private fun saveToPhotos(png: ByteArray): Boolean {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "MeshTrax ${System.currentTimeMillis()}.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/MeshTrax")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val uri = try {
            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        } catch (e: Exception) {
            null
        } ?: return false
        return try {
            contentResolver.openOutputStream(uri)?.use { it.write(png) } ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) },
                    null,
                    null,
                )
            }
            true
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null)
            false
        }
    }

    // Measured at the nearest folder that exists, since the download's own
    // folder may not be made yet. Null when none can be measured.
    private fun freeBytes(path: String): Long? {
        val dir = generateSequence(File(path)) { it.parentFile }.firstOrNull { it.exists() }
            ?: return null
        return try {
            StatFs(dir.path).availableBytes
        } catch (e: IllegalArgumentException) {
            null
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

    // One category's page, where its sound and "Override Do Not Disturb"
    // are set. The category must exist already; without the page, the
    // app's notification settings.
    private fun openNotificationChannelSettings(channelId: String?) {
        if (channelId == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            openNotificationSettings()
            return
        }
        try {
            startActivity(
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    .putExtra(Settings.EXTRA_CHANNEL_ID, channelId),
            )
        } catch (e: ActivityNotFoundException) {
            openNotificationSettings()
        }
    }

    // The SOS alert sounds at the alarm volume: what it is and its most.
    // Null when the phone has no audio service to ask.
    private fun alarmVolume(): Map<String, Int>? {
        val audio = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return null
        return mapOf(
            "volume" to audio.getStreamVolume(AudioManager.STREAM_ALARM),
            "max" to audio.getStreamMaxVolume(AudioManager.STREAM_ALARM),
        )
    }

    // The phone's sound settings, where the alarm volume is set. Without
    // the page, the app's notification settings.
    private fun openSoundSettings() {
        try {
            startActivity(Intent(Settings.ACTION_SOUND_SETTINGS))
        } catch (e: ActivityNotFoundException) {
            openNotificationSettings()
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
