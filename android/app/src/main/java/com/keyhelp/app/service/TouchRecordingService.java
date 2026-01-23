package com.keyhelp.app.service;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.graphics.Path;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;

public class TouchRecordingService extends AccessibilityService {
    private static final String TAG = "TouchRecordService";
    private static TouchRecordingService instance;
    
    public static TouchRecordingService getInstance() {
        return instance;
    }

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        Log.d(TAG, "TouchRecordingService connected");
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // 处理无障碍事件
        Log.d(TAG, "Accessibility event: " + event.getEventType() + ", package: " + event.getPackageName());
    }

    @Override
    public void onInterrupt() {
        Log.d(TAG, "TouchRecordingService interrupted");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        instance = null;
        Log.d(TAG, "TouchRecordingService destroyed");
    }

    public static boolean isConnected() {
        return instance != null;
    }

    // 执行点击
    public boolean performClick(float x, float y) {
        Path path = new Path();
        path.moveTo(x, y);
        
        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, 100));
        
        return dispatchGesture(builder.build(), null, null);
    }

    // 执行滑动
    public boolean performSwipe(float startX, float startY, float endX, float endY, long duration) {
        Path path = new Path();
        path.moveTo(startX, startY);
        path.lineTo(endX, endY);
        
        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, duration));
        
        return dispatchGesture(builder.build(), null, null);
    }

    // 执行长按
    public boolean performLongPress(float x, float y, long duration) {
        Path path = new Path();
        path.moveTo(x, y);
        
        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, duration));
        
        return dispatchGesture(builder.build(), null, null);
    }
}
