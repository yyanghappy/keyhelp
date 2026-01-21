package com.keyhelp.app.service;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.IBinder;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.util.Log;
import android.content.Context;

public class FloatWindowService extends Service {
    private static final String TAG = "FloatWindowService";
    private static final String CHANNEL_ID = "float_window_channel";
    private static final int NOTIFICATION_ID = 1001;
    public static final String ACTION_HIDE = "com.keyhelp.app.action.HIDE_FLOAT";
    public static final String ACTION_SHOW = "com.keyhelp.app.action.SHOW_FLOAT";

    private WindowManager windowManager;
    private View floatView;
    private ImageView closeBtn;
    private ImageView scriptListBtn;
    private ImageView stopBtn;
    private TextView statusText;
    private TextView scriptNameText;

    private static final int ID_CLOSE_BTN = 1;
    private static final int ID_SCRIPT_LIST_BTN = 2;
    private static final int ID_STOP_BTN = 3;
    private static final int ID_STATUS_TEXT = 4;
    private static final int ID_SCRIPT_NAME_TEXT = 5;

    private int originalX = 0;
    private int originalY = 0;
    private int originalXRaw = 0;
    private int originalYRaw = 0;

    private static boolean isRunning = false;
    private static String currentScript = "";
    private static OnFloatWindowListener listener;

    public interface OnFloatWindowListener {
        void onClose();
        void onShowScriptList();
        void onStop();
    }

    public static void setListener(OnFloatWindowListener l) {
        listener = l;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "FloatWindowService created");

        createNotificationChannel();
        startForeground(NOTIFICATION_ID, createNotification());

        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        createFloatWindow();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "浮窗服务",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("保持浮窗服务运行");
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, FloatWindowService.class);
        PendingIntent pendingIntent = PendingIntent.getService(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        Notification.Builder builder = new Notification.Builder(this, CHANNEL_ID);
        builder.setContentTitle("KeyHelp 浮窗");
        builder.setContentText("浮窗服务运行中，点击查看脚本");
        builder.setSmallIcon(android.R.drawable.ic_menu_info_details);
        builder.setContentIntent(pendingIntent);
        builder.setPriority(Notification.PRIORITY_LOW);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setOngoing(true);
            builder.setCategory(Notification.CATEGORY_SERVICE);
        }

        return builder.build();
    }

    public static void setListener(OnFloatWindowListener l) {
        listener = l;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "FloatWindowService created");

        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        createFloatWindow();
    }

    private void createFloatWindow() {
        try {
            int layoutType;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                layoutType = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
            } else {
                layoutType = WindowManager.LayoutParams.TYPE_PHONE;
            }

            WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                    PixelFormat.TRANSLUCENT
            );
            params.gravity = Gravity.TOP | Gravity.START;

            floatView = createFloatLayout();

            windowManager.addView(floatView, params);

            setupViews();
            setupTouchListeners();

            isRunning = true;
            Log.d(TAG, "Float window created");

        } catch (Exception e) {
            Log.e(TAG, "Error creating float window", e);
        }
    }

    private View createFloatLayout() {
        LinearLayout rootLayout = new LinearLayout(this);
        rootLayout.setOrientation(LinearLayout.HORIZONTAL);
        rootLayout.setBackgroundColor(0xCC000000);
        rootLayout.setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8));

        closeBtn = createButton(android.R.drawable.ic_menu_close_clear_cancel);
        scriptListBtn = createButton(android.R.drawable.ic_menu_sort_by_size);
        stopBtn = createButton(android.R.drawable.ic_media_pause);
        stopBtn.setVisibility(View.GONE);

        LinearLayout middleLayout = new LinearLayout(this);
        middleLayout.setOrientation(LinearLayout.VERTICAL);
        middleLayout.setGravity(Gravity.CENTER);
        middleLayout.setPadding(dpToPx(8), 0, dpToPx(8), 0);

        statusText = new TextView(this);
        statusText.setText("未运行");
        statusText.setTextSize(12);
        statusText.setTextColor(0xFFFFFFFF);
        statusText.setPadding(dpToPx(2), dpToPx(2), dpToPx(2), dpToPx(2));

        scriptNameText = new TextView(this);
        scriptNameText.setText("脚本列表");
        scriptNameText.setTextSize(10);
        scriptNameText.setTextColor(0xFFCCCCCC);
        scriptNameText.setMaxWidth(dpToPx(200));
        scriptNameText.setSingleLine(true);

        middleLayout.addView(statusText);
        middleLayout.addView(scriptNameText);

        rootLayout.addView(closeBtn);
        rootLayout.addView(createDivider());
        rootLayout.addView(middleLayout);
        rootLayout.addView(createDivider());
        rootLayout.addView(scriptListBtn);
        rootLayout.addView(createDivider());
        rootLayout.addView(stopBtn);

        return rootLayout;
    }

    private ImageView createButton(int iconRes) {
        ImageView btn = new ImageView(this);
        btn.setImageResource(iconRes);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dpToPx(40), dpToPx(40));
        btn.setLayoutParams(params);
        btn.setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8));
        btn.setBackgroundColor(0x00FFFFFF);
        return btn;
    }

    private View createDivider() {
        View divider = new View(this);
        divider.setBackgroundColor(0xFF333333);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dpToPx(1), dpToPx(40));
        divider.setLayoutParams(params);
        return divider;
    }

    private int dpToPx(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density);
    }

    private void setupTouchListeners() {
        floatView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        originalX = (int) event.getRawX();
                        originalY = (int) event.getRawY();
                        originalXRaw = originalX;
                        originalYRaw = originalY;
                        return true;

                    case MotionEvent.ACTION_MOVE:
                        WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatView.getLayoutParams();
                        int newX = (int) event.getRawX();
                        int newY = (int) event.getRawY();

                        int deltaX = newX - originalX;
                        int deltaY = newY - originalY;

                        params.x += deltaX;
                        params.y += deltaY;
                        windowManager.updateViewLayout(floatView, params);

                        originalX = newX;
                        originalY = newY;
                        return true;

                    case MotionEvent.ACTION_UP:
                        int upX = (int) event.getRawX();
                        int upY = (int) event.getRawY();

                        if (Math.abs(upX - originalXRaw) < 10 && Math.abs(upY - originalYRaw) < 10) {
                        }
                        return true;
                }
                return false;
            }
        });
    }

    private void closeFloatWindow() {
        if (floatView != null && windowManager != null) {
            try {
                windowManager.removeView(floatView);
                isRunning = false;
                Log.d(TAG, "Float window closed");
            } catch (Exception e) {
                Log.e(TAG, "Error removing float window", e);
            }
        }
    }

    public static void updateStatus(String status) {
        currentScript = status;
    }

    public static void updateScriptName(String name) {
        currentScript = name;
    }

    public static void showStopButton(boolean show) {
        // 需要使用 handler 来更新 UI
    }

    public static boolean isRunning() {
        return isRunning;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        super.onStartCommand(intent, flags, startId);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForeground(NOTIFICATION_ID, createNotification());
        }

        if (intent != null) {
            String action = intent.getAction();
            if (ACTION_HIDE.equals(action)) {
                closeFloatWindow();
                isRunning = false;
                stopForeground(true);
            } else if (ACTION_SHOW.equals(action)) {
                if (floatView == null || !floatView.isAttachedToWindow()) {
                    createFloatWindow();
                    isRunning = true;
                }
            } else {
                if (floatView == null || !floatView.isAttachedToWindow()) {
                    createFloatWindow();
                    isRunning = true;
                }
            }
        }

        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        closeFloatWindow();
        stopForeground(true);
        NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        notificationManager.cancel(NOTIFICATION_ID);
        Log.d(TAG, "FloatWindowService destroyed");
    }
}
