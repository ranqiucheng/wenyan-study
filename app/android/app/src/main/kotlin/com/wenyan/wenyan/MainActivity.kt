package com.wenyan.wenyan

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "wenyan/file_picker"
    private val requestCode = 4701
    private var pendingResult: MethodChannel.Result? = null
    private var channel: MethodChannel? = null
    private var pendingInitial: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickContentPack" -> pickContentPack(result)
                "getInitialPack" -> {
                    result.success(pendingInitial)
                    pendingInitial = null
                }
                else -> result.notImplemented()
            }
        }
        handleIntent(intent, deliverToFlutter = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, deliverToFlutter = true)
    }

    private fun handleIntent(intent: Intent?, deliverToFlutter: Boolean) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_VIEW && action != Intent.ACTION_SEND) {
            return
        }
        val uri: Uri? = if (action == Intent.ACTION_VIEW) {
            intent.data
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
        if (uri == null) {
            return
        }
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return
            val payload = mapOf<String, Any>(
                "name" to (displayName(uri) ?: "content.wyc"),
                "bytes" to bytes,
            )
            if (deliverToFlutter) {
                channel?.invokeMethod("incomingPack", payload)
            } else {
                pendingInitial = payload
            }
        } catch (_: Exception) {
        }
    }

    private fun pickContentPack(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "Already picking a file", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        try {
            startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            pendingResult = null
            result.error("NO_PICKER", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == this.requestCode) {
            val result = pendingResult
            pendingResult = null
            if (result == null) {
                return
            }
            if (resultCode != Activity.RESULT_OK) {
                result.success(null)
                return
            }
            val uri: Uri? = data?.data
            if (uri == null) {
                result.success(null)
                return
            }
            try {
                val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                if (bytes == null) {
                    result.error("READ_FAILED", "Cannot read file", null)
                } else {
                    result.success(mapOf("name" to (displayName(uri) ?: "content.wyc"), "bytes" to bytes))
                }
            } catch (e: Exception) {
                result.error("READ_FAILED", e.message, null)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun displayName(uri: Uri): String? {
        var name: String? = null
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0 && cursor.moveToFirst()) {
                    name = cursor.getString(index)
                }
            }
        } catch (_: Exception) {
        }
        return name
    }
}
