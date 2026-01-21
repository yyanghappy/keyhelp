package com.keyhelp.app;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;

import com.keyhelp.app.service.KeyHelpAccessibilityService;

public class AccessibilityMethodChannel {
    private static final String TAG = "AccessibilityMethodChannel";
    private static final String CHANNEL = "com.keyhelp.app/accessibility";
    private MethodChannel channel;
    private Context context;

    public AccessibilityMethodChannel(FlutterEngine flutterEngine, Context context) {
        this.context = context;
        this.channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this::onMethodCall);
    }

    private void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "isServiceEnabled":
                checkAccessibilityService(result);
                break;
            case "openAccessibilitySettings":
                openAccessibilitySettings(result);
                break;
            case "performClick":
                handlePerformClick(call, result);
                break;
            case "performSwipe":
                handlePerformSwipe(call, result);
                break;
            case "performLongPress":
                handlePerformLongPress(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    /**
     * 检查无障碍服务是否启用
     */
    private void checkAccessibilityService(MethodChannel.Result result) {
        boolean enabled = KeyHelpAccessibilityService.isConnected();
        result.success(enabled);
        Log.d(TAG, "Accessibility service enabled: " + enabled);
    }

    /**
     * 打开无障碍设置页面
     */
    private void openAccessibilitySettings(MethodChannel.Result result) {
        try {
            Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Failed to open accessibility settings", e);
            result.error("OPEN_SETTINGS_FAILED", e.getMessage(), null);
        }
    }

    /**
     * 处理点击操作
     */
    private void handlePerformClick(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!KeyHelpAccessibilityService.isConnected()) {
            result.error("SERVICE_NOT_CONNECTED", "Accessibility service not enabled", null);
            return;
        }
 
        try {
            double x = call.argument("x");
            double y = call.argument("y");
            boolean success = KeyHelpAccessibilityService.getInstance().performClick((float) x, (float) y);
            result.success(success);
        } catch (Exception e) {
            Log.e(TAG, "Perform click failed", e);
            result.error("PERFORM_CLICK_FAILED", e.getMessage(), null);
        }
    }

    /**
     * 处理滑动操作
     */
    private void handlePerformSwipe(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!KeyHelpAccessibilityService.isConnected()) {
            result.error("SERVICE_NOT_CONNECTED", "Accessibility service not enabled", null);
            return;
        }
 
        try {
            double startX = call.argument("startX");
            double startY = call.argument("startY");
            double endX = call.argument("endX");
            double endY = call.argument("endY");
            int duration = call.argument("duration");
            
            boolean success = KeyHelpAccessibilityService.getInstance()
                .performSwipe((float) startX, (float) startY, (float) endX, (float) endY, duration);
            result.success(success);
        } catch (Exception e) {
            Log.e(TAG, "Perform swipe failed", e);
            result.error("PERFORM_SWIPE_FAILED", e.getMessage(), null);
        }
    }

    /**
     * 处理长按操作
     */
    private void handlePerformLongPress(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!KeyHelpAccessibilityService.isConnected()) {
            result.error("SERVICE_NOT_CONNECTED", "Accessibility service not enabled", null);
            return;
        }
 
        try {
            double x = call.argument("x");
            double y = call.argument("y");
            int duration = call.argument("duration");
            
            boolean success = KeyHelpAccessibilityService.getInstance().performLongPress((float) x, (float) y, duration);
            result.success(success);
        } catch (Exception e) {
            Log.e(TAG, "Perform long press failed", e);
            result.error("PERFORM_LONG_PRESS_FAILED", e.getMessage(), null);
        }
    }
}
