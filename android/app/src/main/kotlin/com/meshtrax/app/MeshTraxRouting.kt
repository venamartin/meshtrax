package com.meshtrax.app

import android.os.Handler
import android.os.Looper
import com.valhalla.valhalla.Valhalla
import com.valhalla.valhalla.ValhallaException
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * Offline routing with Valhalla as a library (valhalla-mobile). Dart writes the config and the
 * requests (packages/traxroute, ValhallaMobileEngine); this only opens the config and runs the
 * requests, one at a time, off the main thread.
 */
class MeshTraxRouting {
    private val channelName = "meshtrax/routing"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()

    // Touched only on [worker].
    private var valhalla: Valhalla? = null

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> run(result) {
                        closeEngine()
                        valhalla = Valhalla(call.arguments as String)
                        null
                    }
                    "route" -> run(result) { route(call.arguments as String) }
                    "close" -> run(result) {
                        closeEngine()
                        null
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun dispose() {
        worker.execute { closeEngine() }
        worker.shutdown()
    }

    /** Valhalla's JSON, or its refusal in the shape its service answers with. */
    private fun route(request: String): String {
        val engine = valhalla ?: throw IllegalStateException("No routing data open")
        return try {
            engine.routeRaw(request)
        } catch (e: ValhallaException.Internal) {
            JSONObject().put("error", valhallaMessage(e)).toString()
        }
    }

    /** "ValhallaError(code=442, No path could be found for input)" → the message alone. */
    private fun valhallaMessage(e: ValhallaException.Internal): String {
        val text = e.message ?: return "No route"
        val match = Regex("""^ValhallaError\(code=-?\d+, (.*)\)$""", RegexOption.DOT_MATCHES_ALL)
            .find(text)
        return match?.groupValues?.get(1) ?: text
    }

    private fun closeEngine() {
        valhalla?.close()
        valhalla = null
    }

    // Throwable, not Exception: a native library that fails to load throws an Error, and an
    // uncaught one would leave Dart waiting forever.
    private fun run(result: MethodChannel.Result, work: () -> String?) {
        worker.execute {
            try {
                val answer = work()
                mainHandler.post { result.success(answer) }
            } catch (e: Throwable) {
                mainHandler.post { result.error("routing", e.message ?: e.toString(), null) }
            }
        }
    }
}
