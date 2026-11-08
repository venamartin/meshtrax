package com.meshtrax.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * A folder of offline maps on a USB drive, an SD card or the phone's own storage, for "Use a
 * drive" (lib/services/drive_folder.dart). The system folder picker grants it through the
 * Storage Access Framework, so no permission is needed; apps can't open USB drives and SD cards
 * by path, so files are read through the ContentResolver. Copies run off the main thread and
 * can be cancelled.
 */
class MeshTraxDrive(private val activity: Activity) {
    private val channelName = "meshtrax/drive"
    private val pickRequest = 0x4d54
    private val mainHandler = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newCachedThreadPool()
    private val canceled = ConcurrentHashMap.newKeySet<String>()
    private var pending: MethodChannel.Result? = null

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFolder" -> pickFolder(result)
                    "list" -> run(result) { list(Uri.parse(call.arguments as String)) }
                    "readText" -> run(result) { readText(Uri.parse(call.arguments as String)) }
                    "copy" -> run(result) {
                        copy(
                            call.argument<String>("id")!!,
                            Uri.parse(call.argument<String>("uri")),
                            File(call.argument<String>("to")!!),
                            call.argument<Number>("from")?.toLong() ?: 0L,
                        )
                    }
                    "cancelCopy" -> {
                        canceled.add(call.arguments as String)
                        result.success(null)
                    }
                    "isReadable" -> run(result) { isReadable(Uri.parse(call.arguments as String)) }
                    "keepScreenOn" -> {
                        val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        if (call.arguments == true) {
                            activity.window.addFlags(flag)
                        } else {
                            activity.window.clearFlags(flag)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun dispose() {
        worker.shutdown()
    }

    /** Answers the folder picker: true if [requestCode] was this picker's. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != pickRequest) return false
        val result = pending ?: return true
        pending = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(null)
        } else {
            run(result) { mapOf("uri" to tree.toString(), "name" to nameOf(tree)) }
        }
        return true
    }

    private fun pickFolder(result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        try {
            activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), pickRequest)
        } catch (e: ActivityNotFoundException) {
            pending = null
            result.error("drive", "This device has no folder picker", null)
        }
    }

    private fun treeRoot(tree: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    private fun nameOf(tree: Uri): String? =
        activity.contentResolver.query(
            treeRoot(tree),
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null }

    /** Every file in the folder: its path from the top, its size and its document URI. */
    private fun list(tree: Uri): List<Map<String, Any>> {
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        val files = mutableListOf<Map<String, Any>>()
        val folders = ArrayDeque<Pair<String, String>>()
        folders.add(DocumentsContract.getTreeDocumentId(tree) to "")
        while (folders.isNotEmpty()) {
            val (folder, prefix) = folders.removeFirst()
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, folder)
            activity.contentResolver.query(children, columns, null, null, null)?.use { c ->
                while (c.moveToNext()) {
                    val path = prefix + c.getString(1)
                    if (c.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR) {
                        folders.add(c.getString(0) to "$path/")
                    } else {
                        val uri = DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0))
                        files.add(mapOf("path" to path, "size" to c.getLong(3), "uri" to uri.toString()))
                    }
                }
            }
        }
        return files
    }

    private fun readText(uri: Uri): String =
        activity.contentResolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }
            ?: throw IOException("Can't open $uri")

    /** Copies [uri] into [to], from byte [from] on; false when cancelled. */
    private fun copy(id: String, uri: Uri, to: File, from: Long): Boolean {
        val input = activity.contentResolver.openInputStream(uri)
            ?: throw IOException("Can't open $uri")
        input.use {
            var skipped = 0L
            while (skipped < from) {
                val n = input.skip(from - skipped)
                if (n <= 0) throw IOException("Can't read from byte $from")
                skipped += n
            }
            FileOutputStream(to, from > 0).use { output ->
                val buffer = ByteArray(1 shl 20)
                while (true) {
                    if (canceled.remove(id)) return false
                    val n = input.read(buffer)
                    if (n < 0) break
                    output.write(buffer, 0, n)
                }
                output.fd.sync()
            }
        }
        return true
    }

    private fun isReadable(tree: Uri): Boolean = try {
        activity.contentResolver.query(
            treeRoot(tree),
            arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
            null,
            null,
            null,
        )?.use { it.moveToFirst() } ?: false
    } catch (e: Exception) {
        false
    }

    // Throwable, not Exception: an uncaught Error would leave Dart waiting forever.
    private fun run(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val answer = work()
                mainHandler.post { result.success(answer) }
            } catch (e: Throwable) {
                mainHandler.post { result.error("drive", e.message ?: e.toString(), null) }
            }
        }
    }
}
