package com.keyhelp.app.service;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.graphics.Path;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class KeyHelpAccessibilityService extends AccessibilityService {
    private static final String TAG = "KeyHelpAccessibility";
    private static KeyHelpAccessibilityService instance;
    
    // 事件监听器列表
    private static final List<AccessibilityEventListener> eventListeners = new CopyOnWriteArrayList<>();
    
    // 录制状态
    private static boolean isRecording = false;
    private static final List<AccessibilityEvent> recordedEvents = new CopyOnWriteArrayList<>();
    private static ScheduledExecutorService scheduler;
    
    // 当前活动窗口信息
    private String currentPackageName = "";
    private String currentActivityName = "";

    public interface AccessibilityEventListener {
        void onAccessibilityEvent(AccessibilityEvent event);
    }

    public static KeyHelpAccessibilityService getInstance() {
        return instance;
    }

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        Log.d(TAG, "AccessibilityService connected");
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (instance == null) return;

        int eventType = event.getEventType();
        String packageName = event.getPackageName() != null ? event.getPackageName().toString() : "unknown";
        
        // 更新当前窗口信息
        if (eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            currentPackageName = packageName;
            currentActivityName = event.getClassName() != null ? event.getClassName().toString() : "";
        }

        // 记录事件信息
        StringBuilder eventInfo = new StringBuilder();
        eventInfo.append("EventType: ").append(getEventTypeName(eventType));
        eventInfo.append(", Package: ").append(packageName);
        
        if (event.getSource() != null) {
            String viewId = event.getSource().getViewIdResourceName();
            if (viewId != null) {
                eventInfo.append(", ViewId: ").append(viewId);
            }
            String text = getNodeText(event.getSource());
            if (text != null && !text.isEmpty()) {
                eventInfo.append(", Text: ").append(text);
            }
            eventInfo.append(", Class: ").append(event.getSource().getClassName());
        }
        
        Log.d(TAG, eventInfo.toString());

        // 通知监听器
        for (AccessibilityEventListener listener : eventListeners) {
            try {
                listener.onAccessibilityEvent(event);
            } catch (Exception e) {
                Log.e(TAG, "Error notifying listener", e);
            }
        }

        // 如果正在录制，保存事件
        if (isRecording) {
            recordedEvents.add(AccessibilityEvent.obtain(event));
            
            // 每50ms更新一次状态
            notifyRecordingState();
        }
    }

    @Override
    public void onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (scheduler != null) {
            scheduler.shutdown();
        }
        instance = null;
        Log.d(TAG, "AccessibilityService destroyed");
    }

    /**
     * 添加事件监听器
     */
    public static void addEventListener(AccessibilityEventListener listener) {
        if (listener != null && !eventListeners.contains(listener)) {
            eventListeners.add(listener);
        }
    }

    /**
     * 移除事件监听器
     */
    public static void removeEventListener(AccessibilityEventListener listener) {
        eventListeners.remove(listener);
    }

    /**
     * 开始录制
     */
    public void startRecording() {
        if (isRecording) {
            Log.d(TAG, "Recording already in progress");
            return;
        }
        
        recordedEvents.clear();
        isRecording = true;
        Log.d(TAG, "Recording started");
    }

    /**
     * 停止录制
     */
    public List<AccessibilityEvent> stopRecording() {
        if (!isRecording) {
            Log.d(TAG, "No recording in progress");
            return new ArrayList<>();
        }
        
        isRecording = false;
        Log.d(TAG, "Recording stopped, captured " + recordedEvents.size() + " events");
        
        List<AccessibilityEvent> events = new ArrayList<>(recordedEvents);
        recordedEvents.clear();
        return events;
    }

    /**
     * 检查是否正在录制
     */
    public static boolean isRecording() {
        return isRecording;
    }

    /**
     * 获取录制的所有事件
     */
    public static List<AccessibilityEvent> getRecordedEvents() {
        return new ArrayList<>(recordedEvents);
    }

    /**
     * 清空录制的事件
     */
    public static void clearRecordedEvents() {
        recordedEvents.clear();
    }

    /**
     * 获取当前包名
     */
    public static String getCurrentPackageName() {
        if (instance != null) {
            return instance.currentPackageName;
        }
        return "";
    }

    /**
     * 获取当前 Activity 名
     */
    public static String getCurrentActivityName() {
        if (instance != null) {
            return instance.currentActivityName;
        }
        return "";
    }

    /**
     * 通知录制状态更新
     */
    private void notifyRecordingState() {
        for (AccessibilityEventListener listener : eventListeners) {
            try {
                Bundle params = new Bundle();
                params.putInt("recordedCount", recordedEvents.size());
                params.putBoolean("isRecording", isRecording);
            } catch (Exception e) {
                Log.e(TAG, "Error notifying recording state", e);
            }
        }
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
     * 执行手势
     */
    public boolean performGesture(Path path, long duration) {
        if (instance == null) {
            Log.e(TAG, "Service not connected");
            return false;
        }

        GestureDescription.Builder builder = new GestureDescription.Builder();
        builder.addStroke(new GestureDescription.StrokeDescription(path, 0, duration));

        GestureDescription gesture = builder.build();
        return dispatchGesture(gesture, null, null);
    }

    /**
     * 检查服务是否已连接
     */
    public static boolean isConnected() {
        return instance != null;
    }

    /**
     * 获取事件类型名称
     */
    private static String getEventTypeName(int eventType) {
        switch (eventType) {
            case AccessibilityEvent.TYPE_VIEW_CLICKED:
                return "CLICK";
            case AccessibilityEvent.TYPE_VIEW_LONG_CLICKED:
                return "LONG_CLICK";
            case AccessibilityEvent.TYPE_VIEW_SELECTED:
                return "SELECTED";
            case AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED:
                return "TEXT_CHANGED";
            case AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED:
                return "WINDOW_STATE_CHANGED";
            case AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED:
                return "WINDOW_CONTENT_CHANGED";
            case AccessibilityEvent.TYPE_VIEW_SCROLLED:
                return "SCROLLED";
            case AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED:
                return "NOTIFICATION";
            case AccessibilityEvent.TYPE_VIEW_HOVER_ENTER:
                return "HOVER_ENTER";
            case AccessibilityEvent.TYPE_VIEW_HOVER_EXIT:
                return "HOVER_EXIT";
            case AccessibilityEvent.TYPE_GESTURE_DETECTION_START:
                return "GESTURE_START";
            case AccessibilityEvent.TYPE_GESTURE_DETECTION_END:
                return "GESTURE_END";
            default:
                return "UNKNOWN(" + eventType + ")";
        }
    }

    /**
     * 获取节点的文本内容
     */
    private static String getNodeText(AccessibilityNodeInfo node) {
        if (node == null) return null;
        
        CharSequence text = node.getText();
        if (text != null && text.length() > 0) {
            return text.toString();
        }
        
        // 尝试获取内容描述
        CharSequence contentDesc = node.getContentDescription();
        if (contentDesc != null && contentDesc.length() > 0) {
            return contentDesc.toString();
        }
        
        return null;
    }

    /**
     * 获取节点的边界矩形
     */
    private static android.graphics.Rect getNodeBounds(AccessibilityNodeInfo node) {
        android.graphics.Rect bounds = new android.graphics.Rect();
        node.getBoundsInScreen(bounds);
        return bounds;
    }
}
