package com.keyhelp.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall

import com.keyhelp.app.service.FloatWindowService
import java.io.Serializable

class FloatWindowMethodChannel {
    private val TAG = "FloatWindowMethodChannel"
    private val CHANNEL = "com.keyhelp.app/float_window"
    private val EVENT_CHANNEL = "com.keyhelp.app/float_window_events"
    private val channel: MethodChannel
    private val eventChannel: EventChannel
    private val context: Context
    private var eventSink: EventChannel.EventSink? = null

    constructor(flutterEngine: FlutterEngine, appContext: Context) {
        this.context = appContext
        this.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        this.channel.setMethodCallHandler { call, result -> onMethodCall(call, result) }

        this.eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        this.eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                setupServiceListener()
                Log.d(TAG, "Event channel listening")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                FloatWindowService.setListener(null)
                Log.d(TAG, "Event channel cancelled")
            }
        })
    }

    private fun setupServiceListener() {
        FloatWindowService.setListener(object : FloatWindowService.OnFloatWindowListener {
            override fun onClose() {
                Log.d(TAG, "Float window closed event")
                eventSink?.success(mapOf("event" to "windowClosed"))
            }

            override fun onShowScriptList() {
                Log.d(TAG, "Show script list event")
                eventSink?.success(mapOf("event" to "showScriptList"))
            }

            override fun onPlay() {
                Log.d(TAG, "Play event")
                eventSink?.success(mapOf("event" to "play"))
            }

            override fun onPause() {
                Log.d(TAG, "Pause event")
                eventSink?.success(mapOf("event" to "pause"))
            }

            override fun onStop() {
                Log.d(TAG, "Stop execution event")
                eventSink?.success(mapOf("event" to "stop"))
            }

            override fun onExecuteScript(scriptId: String) {
                Log.d(TAG, "Execute script event: $scriptId")
                eventSink?.success(mapOf("event" to "executeScript", "scriptId" to scriptId))
            }
        })
    }

    private fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> checkFloatPermission(result)
            "openPermissionSettings" -> openPermissionSettings(result)
            "showFloatWindow" -> showFloatWindow(result)
            "hideFloatWindow" -> hideFloatWindow(result)
            "isFloating" -> isFloating(result)
            "updateExecutionState" -> updateExecutionState(call, result)
            "setCurrentScript" -> setCurrentScript(call, result)
            "updateScriptName" -> updateScriptName(call, result)
            else -> result.notImplemented()
        }
    }

    private fun checkFloatPermission(result: MethodChannel.Result) {
        try {
            val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(context)
            } else {
                true
            }
            result.success(hasPermission)
            Log.d(TAG, "Float permission: $hasPermission")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check float permission", e)
            result.error("CHECK_PERMISSION_FAILED", e.message, null)
        }
    }

    private fun openPermissionSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent()
            intent.action = Settings.ACTION_MANAGE_OVERLAY_PERMISSION

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val uri = Uri.parse("package:${context.packageName}")
                intent.data = uri
            }

            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(true)
            Log.d(TAG, "Permission settings opened")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open permission settings", e)
            result.error("OPEN_SETTINGS_FAILED", e.message, null)
        }
    }

    private fun showFloatWindow(result: MethodChannel.Result) {
        try {
            val intent = Intent(context, FloatWindowService::class.java)
            context.startService(intent)
            result.success(true)
            Log.d(TAG, "Float window shown")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show float window", e)
            result.error("SHOW_FAILED", e.message, null)
        }
    }

    private fun hideFloatWindow(result: MethodChannel.Result) {
        try {
            val intent = Intent(context, FloatWindowService::class.java)
            intent.action = FloatWindowService.ACTION_HIDE
            context.startService(intent)
            result.success(true)
            Log.d(TAG, "Float window hidden")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to hide float window", e)
            result.error("HIDE_FAILED", e.message, null)
        }
    }

    private fun isFloating(result: MethodChannel.Result) {
        try {
            val isFloating = FloatWindowService.isRunning
            result.success(isFloating)
            Log.d(TAG, "Is floating: $isFloating")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check floating status", e)
            result.error("IS_FLOATING_FAILED", e.message, null)
        }
    }

    private fun updateExecutionState(call: MethodCall, result: MethodChannel.Result) {
        try {
            val state = call.argument<String>("state") ?: "未运行"
            val isPlaying = call.argument<Boolean>("isPlaying") ?: false
            val isPaused = call.argument<Boolean>("isPaused") ?: false

            FloatWindowService.setCurrentScriptId(FloatWindowService.currentScriptId ?: "")
            FloatWindowService.setCurrentScriptName(FloatWindowService.currentScriptName ?: "")

            // 更新浮窗 UI
            FloatWindowService.updateExecutionState(state, isPlaying, isPaused)

            result.success(true)
            Log.d(TAG, "Execution state updated: $state, playing: $isPlaying, paused: $isPaused")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update execution state", e)
            result.error("UPDATE_STATE_FAILED", e.message, null)
        }
    }

    private fun setCurrentScript(call: MethodCall, result: MethodChannel.Result) {
        try {
            val scriptId = call.argument<String>("scriptId")
            val scriptName = call.argument<String>("scriptName")

            FloatWindowService.setCurrentScriptId(scriptId ?: "")
            FloatWindowService.setCurrentScriptName(scriptName ?: "")

            result.success(true)
            Log.d(TAG, "Current script set: $scriptName")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set current script", e)
            result.error("SET_SCRIPT_FAILED", e.message, null)
        }
    }

    private fun updateScriptName(call: MethodCall, result: MethodChannel.Result) {
        try {
            val scriptName = call.argument<String>("scriptName")

            FloatWindowService.setCurrentScriptName(scriptName ?: "")

            result.success(true)
            Log.d(TAG, "Script name updated: $scriptName")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update script name", e)
            result.error("UPDATE_SCRIPT_NAME_FAILED", e.message, null)
        }
    }
}
