package com.keyhelp.app.service;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.graphics.Path;
import android.os.Bundle;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;

public class KeyHelpAccessibilityService extends AccessibilityService {
    private static final String TAG = "KeyHelpAccessibility";
    private static KeyHelpAccessibilityService instance;
    
    public static KeyHelpAccessibilityService getInstance() {
        return instance;
    }

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        Log.d(TAG, "AccessibilityService connected");
        
        // 配置服务
        setServiceInfo(getServiceInfo());
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // 监听界面变化等事件
        int eventType = event.getEventType();
        
        switch (eventType) {
            case AccessibilityEvent.TYPE_VIEW_CLICKED:
                Log.d(TAG, "View clicked: " + event.getClassName());
                break;
            case AccessibilityEvent.TYPE_VIEW_SCROLLED:
                Log.d(TAG, "View scrolled");
                break;
            case AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED:
                Log.d(TAG, "Window changed: " + event.getClassName());
                break;
        }
    }

    @Override
    public void onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        instance = null;
        Log.d(TAG, "AccessibilityService destroyed");
    }

    /**
     * 执行点击操作
     */
    public boolean performClick(float x, float y) {
        if (instance == null) {
            Log.e(TAG, "Service not connected");
            return false;
        }

        Path path = new Path();
        path.moveTo(x, y);

        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, 100));

        GestureDescription gesture = builder.build();
        boolean result = dispatchGesture(gesture, null, null);
        
        Log.d(TAG, "Perform click at (" + x + ", " + y + "): " + result);
        return result;
    }

    /**
     * 执行滑动操作
     */
    public boolean performSwipe(float startX, float startY, float endX, float endY, int duration) {
        if (instance == null) {
            Log.e(TAG, "Service not connected");
            return false;
        }

        Path path = new Path();
        path.moveTo(startX, startY);
        path.lineTo(endX, endY);

        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, duration));

        GestureDescription gesture = builder.build();
        boolean result = dispatchGesture(gesture, null, null);
        
        Log.d(TAG, "Perform swipe: (" + startX + "," + startY + ") -> (" + endX + "," + endY + "): " + result);
        return result;
    }

    /**
     * 执行长按操作
     */
    public boolean performLongPress(float x, float y, int duration) {
        if (instance == null) {
            Log.e(TAG, "Service not connected");
            return false;
        }

        Path path = new Path();
        path.moveTo(x, y);

        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, duration));

        GestureDescription gesture = builder.build();
        boolean result = dispatchGesture(gesture, null, null);
        
        Log.d(TAG, "Perform long press at (" + x + ", " + y + "): " + result);
        return result;
    }

    /**
     * 检查服务是否已连接
     */
    public static boolean isConnected() {
        return instance != null;
    }
}
