package com.keyhelp.app.service;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;
import android.view.WindowManager;
import android.app.AlertDialog;
import java.util.List;
import java.util.ArrayList;

public class GlobalScriptSelectorService extends Service {
    private static final String TAG = "GlobalScriptSelectorService";
    private static List<ScriptInfo> scriptList = new ArrayList<>();

    public static class ScriptInfo {
        public String id;
        public String name;
        public int actionCount;

        public ScriptInfo(String id, String name, int actionCount) {
            this.id = id;
            this.name = name;
            this.actionCount = actionCount;
        }

        @Override
        public String toString() {
            return name + " (" + actionCount + " 个动作)";
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "GlobalScriptSelectorService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            if ("SHOW_SCRIPT_LIST".equals(intent.getAction())) {
                showScriptSelectionDialog();
            } else if ("SET_SCRIPT_LIST".equals(intent.getAction())) {
                // 接收来自Flutter的脚本列表
                List<String> ids = intent.getStringArrayListExtra("script_ids");
                List<String> names = intent.getStringArrayListExtra("script_names");
                List<Integer> actionCounts = intent.getIntegerArrayListExtra("action_counts");

                if (ids != null && names != null && actionCounts != null) {
                    scriptList.clear();
                    for (int i = 0; i < ids.size() && i < names.size() && i < actionCounts.size(); i++) {
                        scriptList.add(new ScriptInfo(ids.get(i), names.get(i), actionCounts.get(i)));
                    }
                    Log.d(TAG, "Script list updated, size: " + scriptList.size());
                }
            }
        }
        return START_NOT_STICKY;
    }

    private void showScriptSelectionDialog() {
        Log.d(TAG, "Showing global script selection dialog, script count: " + scriptList.size());

        if (scriptList.isEmpty()) {
            showNoScriptsDialog();
            return;
        }

        // 准备显示列表项
        String[] items = new String[scriptList.size()];
        for (int i = 0; i < scriptList.size(); i++) {
            items[i] = scriptList.get(i).toString();
        }

        showScriptListDialog(items);
    }

    private void showScriptListDialog(String[] items) {
        try {
            // 创建一个系统级的对话框
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle("选择脚本");

            builder.setItems(items, (dialog, which) -> {
                if (which >= 0 && which < scriptList.size()) {
                    ScriptInfo selectedScript = scriptList.get(which);
                    Log.d(TAG, "Selected script: " + selectedScript.name);
                    // 通知Flutter执行选中的脚本
                    notifyScriptSelected(selectedScript.id);
                }
                dialog.dismiss();
            });

            builder.setNegativeButton("取消", (dialog, which) -> {
                dialog.dismiss();
            });

            AlertDialog dialog = builder.create();
            if (dialog.getWindow() != null) {
                dialog.getWindow().setType(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY);
            }
            dialog.show();
        } catch (Exception e) {
            Log.e(TAG, "Error showing script selection dialog", e);
        }
    }

    private void showNoScriptsDialog() {
        try {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle("脚本列表");
            builder.setMessage("暂无脚本，请先添加脚本");
            builder.setPositiveButton("确定", (dialog, which) -> {
                dialog.dismiss();
            });

            AlertDialog dialog = builder.create();
            if (dialog.getWindow() != null) {
                dialog.getWindow().setType(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY);
            }
            dialog.show();
        } catch (Exception e) {
            Log.e(TAG, "Error showing no scripts dialog", e);
        }
    }

    private void notifyScriptSelected(String scriptId) {
        // 通过广播通知Flutter执行脚本
        Log.d(TAG, "Notifying script selected: " + scriptId);
        Intent broadcastIntent = new Intent("com.keyhelp.app.SCRIPT_SELECTED");
        broadcastIntent.setPackage(getPackageName()); // 限制到当前应用
        broadcastIntent.putExtra("script_id", scriptId);
        // 使用ApplicationContext发送广播以确保能够被接收
        getApplicationContext().sendBroadcast(broadcastIntent);
        Log.d(TAG, "Broadcast sent for script: " + scriptId);
    }

    public static void setScriptList(List<ScriptInfo> scripts) {
        scriptList = scripts;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}