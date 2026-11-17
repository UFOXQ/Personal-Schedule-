package com.tnt.tnt_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val stripChannelName = "tnt/strip"

    /** 通知上的快捷动作（目前只有 quickadd），点进来后由 Dart 取走 */
    private var pendingAction: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        pendingAction = intent?.getStringExtra("tnt_action") ?: pendingAction
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingAction = intent.getStringExtra("tnt_action") ?: pendingAction
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            stripChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val payload = call.argument<String>("payload")
                    if (payload == null) {
                        result.error("no_payload", "payload 不能为空", null)
                    } else {
                        val png = call.argument<ByteArray>("png")
                        runCatching {
                            TimelineStripService.update(applicationContext, payload, png)
                        }
                            .onSuccess { result.success(null) }
                            .onFailure { result.error("strip_failed", it.message, null) }
                    }
                }

                "takeAction" -> {
                    val action = pendingAction
                    pendingAction = null
                    result.success(action)
                }

                "stop" -> {
                    runCatching { TimelineStripService.stop(applicationContext) }
                        .onSuccess { result.success(null) }
                        .onFailure { result.error("strip_failed", it.message, null) }
                }

                else -> result.notImplemented()
            }
        }
    }
}
