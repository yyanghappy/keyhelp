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
    private Button scriptNameBtn;
    private Button playBtn;
    private Button pauseBtn;
    private Button stopBtn;
    private TextView statusText;

    private int originalX = 0;
    private int originalY = 0;

    private static boolean isRunning = false;
    private static OnFloatWindowListener listener;
    private static FloatWindowService instance;
    private static String currentScriptId = null;
    private static String currentScriptName = null;
    private static boolean isPaused = false;

    public interface OnFloatWindowListener {
        void onClose();
        void onShowScriptList();
        void onPlay();
        void onPause();
        void onStop();
    }

    public static String getCurrentScriptId() {
        return currentScriptId;
    }

    public static String getCurrentScriptName() {
        return currentScriptName;
    }

    public static void setCurrentScriptId(String scriptId) {
        currentScriptId = scriptId;
    }

    public static void setCurrentScriptName(String scriptName) {
        currentScriptName = scriptName;
    }

    public static void clearCurrentScript() {
        currentScriptId = null;
        currentScriptName = null;
        isPaused = false;
    }

    public static void setListener(OnFloatWindowListener l) {
        listener = l;
    }

    public static boolean isRunning() {
        return isRunning;
    }

    public static FloatWindowService getInstance() {
        return instance;
    }

    public static void setExecutionState(String state) {
    }

    public void updateExecutionState(String state, boolean isPlaying, boolean isPaused) {
        Log.d(TAG, "updateExecutionState: state=" + state + ", isPlaying=" + isPlaying + ", isPaused=" + isPaused + ", currentScriptId=" + currentScriptId);
        if (statusText != null) {
            statusText.setText(state);
        }
        FloatWindowService.isPaused = isPaused;

        if (!isPlaying) {
        }

        if (scriptNameBtn != null) {
            if (currentScriptName == null) {
                scriptNameBtn.setText("≡");
                scriptNameBtn.setEnabled(false);
            } else {
                scriptNameBtn.setText(currentScriptName);
                scriptNameBtn.setEnabled(false);
            }
        }

        if (playBtn != null) {
            if (currentScriptId == null) {
                playBtn.setVisibility(View.GONE);
            } else if (!isPlaying) {
                playBtn.setText("▶");
                playBtn.setVisibility(View.VISIBLE);
            } else if (isPaused) {
                playBtn.setText("▶");
                playBtn.setVisibility(View.VISIBLE);
            } else {
                playBtn.setText("▶");
                playBtn.setVisibility(View.GONE);
            }
        }
        if (pauseBtn != null) {
            pauseBtn.setVisibility(isPlaying && !isPaused ? View.VISIBLE : View.GONE);
        }
        if (stopBtn != null) {
            stopBtn.setVisibility(isPlaying ? View.VISIBLE : View.GONE);
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "FloatWindowService created");

        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        instance = this;
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
            if (floatLayout != null) {
                Log.d(TAG, "Existing floatLayout found, cleaning up before creating new one");
                closeFloatWindow();
            }

            floatLayout = new LinearLayout(this);
            floatLayout.setOrientation(LinearLayout.HORIZONTAL);
            floatLayout.setBackgroundColor(0xCC000000);
            int padding = dpToPx(12);
            floatLayout.setPadding(padding, padding, padding, padding);

            int buttonSize = dpToPx(48);

            closeBtn = new Button(this);
            closeBtn.setText("×");
            closeBtn.setTextSize(24);
            closeBtn.setTextColor(0xFFFFFFFF);
            closeBtn.setBackgroundColor(0x00FFFFFF);
            closeBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));

            scriptNameBtn = new Button(this);
            scriptNameBtn.setText("≡");
            scriptNameBtn.setTextSize(24);
            scriptNameBtn.setTextColor(0xFFFFFFFF);
            scriptNameBtn.setBackgroundColor(0x00FFFFFF);
            scriptNameBtn.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(80), buttonSize));

            playBtn = new Button(this);
            playBtn.setText("▶");
            playBtn.setTextSize(24);
            playBtn.setTextColor(0xFFFFFFFF);
            playBtn.setBackgroundColor(0x00FFFFFF);
            playBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));
            playBtn.setVisibility(View.GONE);

            pauseBtn = new Button(this);
            pauseBtn.setText("⏸");
            pauseBtn.setTextSize(24);
            pauseBtn.setTextColor(0xFFFFFFFF);
            pauseBtn.setBackgroundColor(0x00FFFFFF);
            pauseBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));
            pauseBtn.setVisibility(View.GONE);

            stopBtn = new Button(this);
            stopBtn.setText("■");
            stopBtn.setTextSize(24);
            stopBtn.setTextColor(0xFFFFFFFF);
            stopBtn.setBackgroundColor(0x00FFFFFF);
            stopBtn.setLayoutParams(new LinearLayout.LayoutParams(buttonSize, buttonSize));
            stopBtn.setVisibility(View.GONE);

            statusText = new TextView(this);
            statusText.setText("未运行");
            statusText.setTextSize(dpToPx(14));
            statusText.setTextColor(0xFFFFFFFF);
            statusText.setPadding(dpToPx(12), dpToPx(8), dpToPx(12), dpToPx(8));
            statusText.setMinWidth(dpToPx(120));
            statusText.setMinHeight(buttonSize);

            floatLayout.addView(closeBtn);

            View divider1 = new View(this);
            divider1.setBackgroundColor(0xFF444444);
            divider1.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(2), buttonSize));
            floatLayout.addView(divider1);

            floatLayout.addView(scriptNameBtn);

            View divider2 = new View(this);
            divider2.setBackgroundColor(0xFF444444);
            divider2.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(2), buttonSize));
            floatLayout.addView(divider2);

            floatLayout.addView(statusText);

            View divider3 = new View(this);
            divider3.setBackgroundColor(0xFF444444);
            divider3.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(2), buttonSize));
            floatLayout.addView(divider3);

            floatLayout.addView(playBtn);

            View divider4 = new View(this);
            divider4.setBackgroundColor(0xFF444444);
            divider4.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(2), buttonSize));
            floatLayout.addView(divider4);

            floatLayout.addView(pauseBtn);

            View divider5 = new View(this);
            divider5.setBackgroundColor(0xFF444444);
            divider5.setLayoutParams(new LinearLayout.LayoutParams(dpToPx(2), buttonSize));
            floatLayout.addView(divider5);

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
                Log.d(TAG, "Close button clicked");
                closeFloatWindow();
                if (listener != null) {
                    listener.onClose();
                }
            }
        });

        scriptNameBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(TAG, "Script name button clicked");
                if (listener != null) {
                    listener.onShowScriptList();
                }
            }
        });

        playBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(TAG, "Play button clicked, currentScriptId: " + currentScriptId);
                if (listener != null) {
                    listener.onPlay();
                }
            }
        });

        pauseBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(TAG, "Pause button clicked, isPaused: " + isPaused);
                if (listener != null) {
                    listener.onPause();
                }
            }
        });

        stopBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(TAG, "Stop button clicked");
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
                        if (floatLayout != null && floatLayout.isAttachedToWindow()) {
                            WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatLayout.getLayoutParams();
                            if (params != null) {
                                int newX = (int) event.getRawX();
                                int newY = (int) event.getRawY();

                                int deltaX = newX - originalX;
                                int deltaY = newY - originalY;

                                params.x += deltaX;
                                params.y += deltaY;
                                windowManager.updateViewLayout(floatLayout, params);

                                originalX = newX;
                                originalY = newY;
                            }
                        }
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
                if (floatLayout.isAttachedToWindow()) {
                    windowManager.removeView(floatLayout);
                }
                floatLayout = null;
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
