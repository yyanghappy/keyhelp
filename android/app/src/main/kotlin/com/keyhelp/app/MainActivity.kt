package com.keyhelp.app

import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.keyhelp.app.service.KeyHelpAccessibilityService
import com.keyhelp.app.service.FloatWindowService
import com.keyhelp.app.receiver.ScriptSelectedReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentLinkedQueue

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    private val MAX_BUFFER_SIZE = 100  // 最多缓存100个事件

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isRecording = false
    private var scriptSelectedReceiver: ScriptSelectedReceiver? = null

    // Flutter engine 状态管理
    private var flutterEngine: FlutterEngine? = null
    private var isFlutterEngineAttached = true

    // 事件缓冲区 - 用于 Flutter detached 时缓存事件
    private val eventBuffer = ConcurrentLinkedQueue<Map<String, Any?>>()
    private var isFlushingBuffer = false

    override fun onStart() {
        super.onStart()
        registerScriptSelectedReceiver()
    }

    override fun onStop() {
        super.onStop()
        unregisterScriptSelectedReceiver()
    }

    private fun registerScriptSelectedReceiver() {
        try {
            scriptSelectedReceiver = ScriptSelectedReceiver()
            ScriptSelectedReceiver.setListener(object : ScriptSelectedReceiver.ScriptSelectedListener {
                override fun onScriptSelected(scriptId: String) {
                    // 通过事件通道通知Flutter执行脚本
                    sendScriptSelectedEvent(scriptId)
                }
            })

            val intentFilter = IntentFilter("com.keyhelp.app.SCRIPT_SELECTED")
            registerReceiver(scriptSelectedReceiver, intentFilter)
            Log.d(TAG, "ScriptSelectedReceiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register ScriptSelectedReceiver", e)
        }
    }

    private fun unregisterScriptSelectedReceiver() {
        try {
            if (scriptSelectedReceiver != null) {
                unregisterReceiver(scriptSelectedReceiver)
                scriptSelectedReceiver = null
                Log.d(TAG, "ScriptSelectedReceiver unregistered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister ScriptSelectedReceiver", e)
        }
    }

    private fun sendScriptSelectedEvent(scriptId: String) {
        try {
            if (isFlutterEngineAttached && eventSink != null) {
                val eventMap = mapOf(
                    "event" to "executeScript",
                    "scriptId" to scriptId
                )
                eventSink?.success(eventMap)
                Log.d(TAG, "Script selected event sent to Flutter: $scriptId")
            } else {
                Log.w(TAG, "Cannot send script selected event, Flutter not attached")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send script selected event", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化无障碍服务 MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.keyhelp.app/accessibility")
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.keyhelp.app/accessibility_events")
        
        setupAccessibilityChannels()
        
        // 初始化悬浮窗 MethodChannel
        FloatWindowMethodChannel(flutterEngine, applicationContext)
    }

    private fun setupAccessibilityChannels() {
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                isFlutterEngineAttached = true
                Log.d(TAG, "Accessibility EventChannel listener attached, flushing buffer: ${eventBuffer.size}")

                flushEventBuffer()

                KeyHelpAccessibilityService.addEventListener { event ->
                    try {
                        val eventMap = hashMapOf<String, Any?>()
                        eventMap["eventType"] = getEventTypeName(event.eventType)
                        eventMap["packageName"] = event.packageName
                        eventMap["className"] = event.className
                        eventMap["isRecording"] = isRecording

                        var hasBounds = false
                        event.source?.let { source ->
                            eventMap["viewId"] = source.viewIdResourceName
                            eventMap["nodeText"] = source.text
                            eventMap["nodeClass"] = source.className

                            val bounds = android.graphics.Rect()
                            source.getBoundsInScreen(bounds)
                            eventMap["bounds"] = mapOf(
                                "left" to bounds.left,
                                "top" to bounds.top,
                                "right" to bounds.right,
                                "bottom" to bounds.bottom
                            )
                            hasBounds = true
                        }

                        if (isFlutterEngineAttached && eventSink != null) {
                            Log.d(TAG, "Sending event to Flutter: type=${eventMap["eventType"]}, pkg=${eventMap["packageName"]}, hasBounds=$hasBounds")
                            eventSink?.success(eventMap)
                        } else if (!isFlutterEngineAttached) {
                            bufferEvent(eventMap)
                        } else {
                            Log.w(TAG, "EventSink is null, skipping event")
                        }
                    } catch (e: Exception) {
                        if (!isFlutterEngineAttached) {
                            Log.w(TAG, "Flutter detached, buffering event after error")
                        } else {
                            Log.e(TAG, "Error sending accessibility event", e)
                        }
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                isFlutterEngineAttached = false
                eventSink = null
                KeyHelpAccessibilityService.removeEventListener { }
                Log.d(TAG, "Accessibility EventChannel cancelled")
            }
        })
        
        // MethodChannel - 无障碍服务控制
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isServiceEnabled" -> {
                    result.success(KeyHelpAccessibilityService.isConnected())
                }
                
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error opening accessibility settings", e)
                        result.error("OPEN_SETTINGS_FAILED", e.message, null)
                    }
                }
                
                "startRecording" -> {
                    KeyHelpAccessibilityService.getInstance()?.startRecording()
                    isRecording = true
                    result.success(true)
                }
                
                "stopRecording" -> {
                    KeyHelpAccessibilityService.getInstance()?.stopRecording()
                    isRecording = false
                    result.success(true)
                }
                
                "isRecording" -> {
                    result.success(isRecording)
                }
                
                "getCurrentPackageName" -> {
                    result.success(KeyHelpAccessibilityService.getCurrentPackageName())
                }
                
                "getCurrentActivityName" -> {
                    result.success(KeyHelpAccessibilityService.getCurrentActivityName())
                }
                
                "performClick" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val success = KeyHelpAccessibilityService.getInstance()?.performClick(x, y) ?: false
                    result.success(success)
                }
                
                "performSwipe" -> {
                    val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                    val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                    val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                    val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration") ?: 300
                    val success = KeyHelpAccessibilityService.getInstance()?.performSwipe(startX, startY, endX, endY, duration) ?: false
                    result.success(success)
                }
                
                "performLongPress" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration") ?: 500
                    val success = KeyHelpAccessibilityService.getInstance()?.performLongPress(x, y, duration) ?: false
                    result.success(success)
                }
                
                else -> result.notImplemented()
            }
        }
    }

    private fun getEventTypeName(eventType: Int): String {
        return when (eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED -> "click"
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED -> "longclick"
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> "textchanged"
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "windowstatechanged"
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> "windowcontentchanged"
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> "scrolled"
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> "notification"
            else -> "other"
        }
    }

    private fun bufferEvent(event: Map<String, Any?>) {
        if (eventBuffer.size >= MAX_BUFFER_SIZE) {
            eventBuffer.poll()
        }
        eventBuffer.offer(event)
        Log.d(TAG, "Buffered event, buffer size: ${eventBuffer.size}")
    }

    private fun flushEventBuffer() {
        if (isFlushingBuffer) {
            Log.d(TAG, "Already flushing buffer, skipping")
            return
        }

        isFlushingBuffer = true
        val sink = eventSink

        if (sink == null) {
            Log.w(TAG, "Cannot flush buffer: EventSink is null")
            isFlushingBuffer = false
            return
        }

        Log.d(TAG, "Flushing ${eventBuffer.size} buffered events")

        while (eventBuffer.isNotEmpty()) {
            val event = eventBuffer.poll() ?: break
            try {
                sink.success(event)
                Log.d(TAG, "Flushed buffered event")
            } catch (e: Exception) {
                Log.e(TAG, "Error flushing buffered event", e)
                break
            }
        }

        isFlushingBuffer = false
        Log.d(TAG, "Buffer flush complete, remaining: ${eventBuffer.size}")
    }
}
