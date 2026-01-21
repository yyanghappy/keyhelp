package com.keyhelp.app.service;

import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.IBinder;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.util.Log;

public class FloatWindowService extends Service {
    private static final String TAG = "FloatWindowService";
    public static final String ACTION_HIDE = "com.keyhelp.app.action.HIDE_FLOAT";
    public static final String ACTION_SHOW = "com.keyhelp.app.action.SHOW_FLOAT";

    private WindowManager windowManager;
    private LinearLayout floatLayout;
    private Button closeBtn;
    private Button scriptListBtn;
    private Button stopBtn;
    private TextView statusText;

    private int originalX = 0;
    private int originalY = 0;

    private static boolean isRunning = false;
    private static OnFloatWindowListener listener;

    public interface OnFloatWindowListener {
        void onClose();
        void onShowScriptList();
        void onStop();
    }

    public static void setListener(OnFloatWindowListener l) {
        listener = l;
    }

    public static boolean isRunning() {
        return isRunning;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "FloatWindowService created");

        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        createFloatWindow();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        super.onStartCommand(intent, flags, startId);

        if (intent != null && ACTION_HIDE.equals(intent.getAction())) {
            closeFloatWindow();
            isRunning = false;
        } else {
            if (floatLayout == null || !floatLayout.isAttachedToWindow()) {
                createFloatWindow();
                isRunning = true;
            }
        }

        return START_STICKY;
    }

    private void createFloatWindow() {
        try {
            floatLayout = new LinearLayout(this);
            floatLayout.setOrientation(LinearLayout.HORIZONTAL);
            floatLayout.setBackgroundColor(0xCC000000);
            int padding = dpToPx(8);
            floatLayout.setPadding(padding, padding, padding, padding);

            int buttonSize = dpToPx(40);
            int dividerWidth = 1;

            closeBtn = new Button(this);
            closeBtn.setText("×");
            closeBtn.setTextSize(24);
            closeBtn.setTextColor(0xFFFFFFFF);
            closeBtn.setBackgroundColor(0x00FFFFFF);
            closeBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));

            scriptListBtn = new Button(this);
            scriptListBtn.setText("≡");
            scriptListBtn.setTextSize(20);
            scriptListBtn.setTextColor(0xFFFFFFFF);
            scriptListBtn.setBackgroundColor(0x00FFFFFF);
            scriptListBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));

            stopBtn = new Button(this);
            stopBtn.setText("■");
            stopBtn.setTextSize(16);
            stopBtn.setTextColor(0xFF000000);
            stopBtn.setBackgroundColor(0x00FFFFFF);
            stopBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));
            stopBtn.setVisibility(View.GONE);

            statusText = new TextView(this);
            statusText.setText("未运行");
            statusText.setTextSize(dpToPx(12));
            statusText.setTextColor(0xFFFFFFFF);
            statusText.setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(4));

            LinearLayout middleLayout = new LinearLayout(this);
            middleLayout.setOrientation(LinearLayout.VERTICAL);
            middleLayout.setGravity(Gravity.CENTER);
            middleLayout.setPadding(dpToPx(8), 0, dpToPx(8), 0);
            middleLayout.addView(statusText);

            View divider1 = new View(this);
            divider1.setBackgroundColor(0xFF333333);
            divider1.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(200), dividerWidth));

            View divider2 = new View(this);
            divider2.setBackgroundColor(0xFF333333);
            divider2.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(200), dividerWidth));

            floatLayout.addView(closeBtn);
            floatLayout.addView(divider1);
            floatLayout.addView(middleLayout);
            floatLayout.addView(divider2);
            floatLayout.addView(scriptListBtn);
            floatLayout.addView(divider1);
            floatLayout.addView(stopBtn);

            setupButtons();

            int layoutType;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
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
            params.x = 100;
            params.y = 200;

            windowManager.addView(floatLayout, params);

            setupTouchListeners();

            Log.d(TAG, "Float window created");

        } catch (Exception e) {
            Log.e(TAG, "Error creating float window", e);
        }
    }

    private void setupButtons() {
        closeBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                closeFloatWindow();
                if (listener != null) {
                    listener.onClose();
                }
            }
        });

        scriptListBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (listener != null) {
                    listener.onShowScriptList();
                }
            }
        });

        stopBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (listener != null) {
                    listener.onStop();
                }
            }
        });
    }

    private void setupTouchListeners() {
        floatLayout.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        originalX = (int) event.getRawX();
                        originalY = (int) event.getRawY();
                        return true;

                    case MotionEvent.ACTION_MOVE:
                        WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatLayout.getLayoutParams();
                        int newX = (int) event.getRawX();
                        int newY = (int) event.getRawY();

                        int deltaX = newX - originalX;
                        int deltaY = newY - originalY;

                        params.x += deltaX;
                        params.y += deltaY;
                        windowManager.updateViewLayout(floatLayout, params);

                        originalX = newX;
                        originalY = newY;
                        return true;

                    case MotionEvent.ACTION_UP:
                        return true;
                }
                return false;
            }
        });
    }

    private void closeFloatWindow() {
        if (floatLayout != null && windowManager != null) {
            try {
                windowManager.removeView(floatLayout);
                isRunning = false;
                Log.d(TAG, "Float window closed");
            } catch (Exception e) {
                Log.e(TAG, "Error removing float window", e);
            }
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        closeFloatWindow();
        Log.d(TAG, "FloatWindowService destroyed");
    }

    private int dpToPx(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density);
    }
}
