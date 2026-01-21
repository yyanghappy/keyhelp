package com.keyhelp.app.service;

import android.app.Service;
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
import android.widget.TextView;
import android.util.Log;
import com.keyhelp.app.R;

public class FloatWindowService extends Service {
    private static final String TAG = "FloatWindowService";
    private WindowManager windowManager;
    private View floatView;
    private ImageView closeBtn;
    private ImageView scriptListBtn;
    private ImageView stopBtn;
    private TextView statusText;
    private TextView scriptNameText;

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

        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        createFloatWindow();
    }

    private void createFloatWindow() {
        try {
            LayoutInflater layoutInflater = LayoutInflater.from(this);
            floatView = layoutInflater.inflate(R.layout.float_window, null);

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
            params.x = 100;
            params.y = 200;

            windowManager.addView(floatView, params);

            setupViews();
            setupTouchListeners();

            isRunning = true;
            Log.d(TAG, "Float window created");

        } catch (Exception e) {
            Log.e(TAG, "Error creating float window", e);
        }
    }

    private void setupViews() {
        closeBtn = floatView.findViewById(R.id.closeBtn);
        scriptListBtn = floatView.findViewById(R.id.scriptListBtn);
        stopBtn = floatView.findViewById(R.id.stopBtn);
        statusText = floatView.findViewById(R.id.statusText);
        scriptNameText = floatView.findViewById(R.id.scriptNameText);

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
    public void onDestroy() {
        super.onDestroy();
        closeFloatWindow();
        Log.d(TAG, "FloatWindowService destroyed");
    }
}
