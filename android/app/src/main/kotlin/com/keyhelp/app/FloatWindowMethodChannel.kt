package com.keyhelp.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall

import com.keyhelp.app.service.FloatWindowService

class FloatWindowMethodChannel {
    private val TAG = "FloatWindowMethodChannel"
    private val CHANNEL = "com.keyhelp.app/float_window"
    private val channel: MethodChannel
    private val context: Context

    constructor(flutterEngine: FlutterEngine, appContext: Context) {
        this.context = appContext
        this.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result -> onMethodCall(call, result) }
    }

    private fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> checkFloatPermission(result)
            "openPermissionSettings" -> openPermissionSettings(result)
            "showFloatWindow" -> showFloatWindow(result)
            "hideFloatWindow" -> hideFloatWindow(result)
            "isFloating" -> isFloating(result)
            else -> result.notImplemented()
        }
    }

    private fun checkFloatPermission(result: MethodChannel.Result) {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
        result.success(hasPermission)
        Log.d(TAG, "Float permission: $hasPermission")
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
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open permission settings", e)
            result.error("OPEN_SETTINGS_FAILED", e.message, null)
        }
    }

    private fun showFloatWindow(result: MethodChannel.Result) {
        try {
            val intent = Intent(context, FloatWindowService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
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
            context.stopService(intent)
            result.success(true)
            Log.d(TAG, "Float window hidden")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to hide float window", e)
            result.error("HIDE_FAILED", e.message, null)
        }
    }

    private fun isFloating(result: MethodChannel.Result) {
        val isFloating = FloatWindowService.isRunning()
        result.success(isFloating)
    }
}
