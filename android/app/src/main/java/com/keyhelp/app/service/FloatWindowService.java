package com.keyhelp.app.service;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.PixelFormat;
import android.os.IBinder;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.util.Log;
import com.keyhelp.app.R;

public class FloatWindowService extends Service {
    private static final String TAG = "FloatWindowService";
    private static final String PREFS_NAME = "float_window_prefs";
    private static final String KEY_POSITION_X = "position_x";
    private static final String KEY_POSITION_Y = "position_y";
    public static final String ACTION_HIDE = "com.keyhelp.app.action.HIDE_FLOAT";
    public static final String ACTION_SHOW = "com.keyhelp.app.action.SHOW_FLOAT";

    private WindowManager windowManager;
    private LinearLayout floatLayout;
    private ImageView closeBtn;
    private ImageView minimizeBtn;
    private LinearLayout scriptInfoContainer;
    private TextView statusText;
    private TextView scriptNameText;
    private ImageView playBtn;
    private ImageView pauseBtn;
    private ImageView stopBtn;
    private boolean isMinimized = false;
    public static String currentScriptId = null;
    public static String currentScriptName = null;
    public static boolean isPaused = false;

    private int originalX = 0;
    private int originalY = 0;
    private int downX = 0;
    private int downY = 0;
    private boolean isDragging = false;

    public static boolean isRunning = false;

    private static OnFloatWindowListener listener;

    public interface OnFloatWindowListener {
        void onClose();
        void onShowScriptList();
        void onPlay();
        void onPause();
        void onStop();
        void onExecuteScript(String scriptId);
    }

    public static void setListener(OnFloatWindowListener l) {
        listener = l;
    }

    public static void setCurrentScriptId(String scriptId) {
        currentScriptId = scriptId;
    }

    public static void setCurrentScriptName(String scriptName) {
        currentScriptName = scriptName;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        Log.d(TAG, "FloatWindowService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && intent.getAction() != null) {
            if (ACTION_SHOW.equals(intent.getAction())) {
                showFloatWindow();
            } else if (ACTION_HIDE.equals(intent.getAction())) {
                hideFloatWindow();
            }
        } else {
            // 没有action时，直接显示悬浮窗（首次启动）
            showFloatWindow();
        }
        return START_STICKY;
    }

    private void showFloatWindow() {
        if (!isRunning) {
            createFloatWindow();
            isRunning = true;
        }
    }

    private void hideFloatWindow() {
        if (floatLayout != null) {
            windowManager.removeView(floatLayout);
            floatLayout = null;
        }
        isRunning = false;
    }

    private void createFloatWindow() {
        try {
            if (floatLayout != null) {
                Log.d(TAG, "Existing floatLayout found, cleaning up before creating new one");
                closeFloatWindow();
            }

            LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            floatLayout = (LinearLayout) inflater.inflate(R.layout.float_window, null);

            closeBtn = (ImageView) floatLayout.findViewById(R.id.closeBtn);
            minimizeBtn = (ImageView) floatLayout.findViewById(R.id.minimizeBtn);
            scriptInfoContainer = (LinearLayout) floatLayout.findViewById(R.id.scriptInfoContainer);
            statusText = (TextView) floatLayout.findViewById(R.id.statusText);
            scriptNameText = (TextView) floatLayout.findViewById(R.id.scriptNameText);
            playBtn = (ImageView) floatLayout.findViewById(R.id.playBtn);
            pauseBtn = (ImageView) floatLayout.findViewById(R.id.pauseBtn);
            stopBtn = (ImageView) floatLayout.findViewById(R.id.stopBtn);

            setupButtons();
            setupTouchListeners();

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

            int[] position = loadPosition();
            params.x = position[0];
            params.y = position[1];

            windowManager.addView(floatLayout, params);
            Log.d(TAG, "Float window created successfully");

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

        minimizeBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(TAG, "Minimize button clicked, isMinimized: " + isMinimized);
                if (isMinimized) {
                    expandWindow();
                } else {
                    minimizeWindow();
                }
            }
        });

        scriptInfoContainer.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.d(TAG, "Script info container clicked");
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
                        downX = (int) event.getRawX();
                        downY = (int) event.getRawY();
                        originalX = downX;
                        originalY = downY;
                        isDragging = false;
                        return true;

                    case MotionEvent.ACTION_MOVE:
                        if (floatLayout != null && floatLayout.isAttachedToWindow()) {
                            int newX = (int) event.getRawX();
                            int newY = (int) event.getRawY();

                            int deltaX = newX - originalX;
                            int deltaY = newY - originalY;

                            int touchSlop = (int) (10 * getResources().getDisplayMetrics().density);
                            if (Math.abs(newX - downX) > touchSlop || Math.abs(newY - downY) > touchSlop) {
                                isDragging = true;
                            }

                            if (isDragging) {
                                WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatLayout.getLayoutParams();
                                if (params != null) {
                                    params.x += deltaX;
                                    params.y += deltaY;
                                    windowManager.updateViewLayout(floatLayout, params);
                                }
                            }

                            originalX = newX;
                            originalY = newY;
                        }
                        return true;

                    case MotionEvent.ACTION_UP:
                        if (!isDragging) {
                            return false;
                        }
                        isDragging = false;
                        snapToEdge();
                        return true;
                }
                return false;
            }
        });
    }

    private void snapToEdge() {
        if (floatLayout == null || !floatLayout.isAttachedToWindow()) {
            return;
        }

        WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatLayout.getLayoutParams();
        if (params == null) {
            return;
        }

        int screenWidth = getResources().getDisplayMetrics().widthPixels;
        int windowWidth = floatLayout.getWidth();

        int halfScreen = screenWidth / 2;
        if (params.x < halfScreen) {
            params.x = 0;
        } else {
            params.x = screenWidth - windowWidth;
        }

        windowManager.updateViewLayout(floatLayout, params);
        savePosition(params.x, params.y);
    }

    private void minimizeWindow() {
        if (floatLayout == null || !floatLayout.isAttachedToWindow()) {
            return;
        }

        WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatLayout.getLayoutParams();
        if (params == null) {
            return;
        }

        savePosition(params.x, params.y);

        scriptInfoContainer.setVisibility(View.GONE);
        playBtn.setVisibility(View.GONE);
        pauseBtn.setVisibility(View.GONE);
        stopBtn.setVisibility(View.GONE);

        params.width = WindowManager.LayoutParams.WRAP_CONTENT;
        params.height = WindowManager.LayoutParams.WRAP_CONTENT;
        windowManager.updateViewLayout(floatLayout, params);

        isMinimized = true;
        Log.d(TAG, "Window minimized");
    }

    private void expandWindow() {
        if (floatLayout == null || !floatLayout.isAttachedToWindow()) {
            return;
        }

        scriptInfoContainer.setVisibility(View.VISIBLE);

        if (currentScriptId != null) {
            boolean isPlaying = false;
            boolean isPaused = false;
            if (playBtn.getVisibility() == View.VISIBLE && !isPaused) {
                isPlaying = true;
            }
            playBtn.setVisibility(isPlaying && !isPaused ? View.GONE : View.VISIBLE);
            pauseBtn.setVisibility(isPlaying && !isPaused ? View.VISIBLE : View.GONE);
            stopBtn.setVisibility(isPlaying ? View.VISIBLE : View.GONE);
        }

        WindowManager.LayoutParams params = (WindowManager.LayoutParams) floatLayout.getLayoutParams();
        params.width = WindowManager.LayoutParams.WRAP_CONTENT;
        params.height = WindowManager.LayoutParams.WRAP_CONTENT;
        windowManager.updateViewLayout(floatLayout, params);

        isMinimized = false;
        Log.d(TAG, "Window expanded");
    }

    private void savePosition(int x, int y) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putInt(KEY_POSITION_X, x);
        editor.putInt(KEY_POSITION_Y, y);
        editor.apply();
    }

    private int[] loadPosition() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        int x = prefs.getInt(KEY_POSITION_X, 100);
        int y = prefs.getInt(KEY_POSITION_Y, 200);
        return new int[]{x, y};
    }

    private void closeFloatWindow() {
        if (floatLayout != null) {
            windowManager.removeView(floatLayout);
            floatLayout = null;
        }
        isRunning = false;
        Log.d(TAG, "Float window closed");
    }

    public void updateExecutionState(String state, boolean isPlaying, boolean isPaused) {
        Log.d(TAG, "updateExecutionState: state=" + state + ", isPlaying=" + isPlaying + ", isPaused=" + isPaused + ", currentScriptId=" + currentScriptId);
        if (statusText != null) {
            statusText.setText(state);
        }
        FloatWindowService.isPaused = isPaused;

        if (!isPlaying) {
        }

        if (scriptNameText != null) {
            if (currentScriptName == null) {
                scriptNameText.setText("脚本列表");
            } else {
                scriptNameText.setText(currentScriptName);
            }
        }

        if (playBtn != null) {
            if (currentScriptId == null) {
                playBtn.setVisibility(View.GONE);
            } else if (!isPlaying) {
                playBtn.setVisibility(View.VISIBLE);
            } else if (isPaused) {
                playBtn.setVisibility(View.VISIBLE);
            } else {
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
    public void onDestroy() {
        super.onDestroy();
        closeFloatWindow();
        Log.d(TAG, "FloatWindowService destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
