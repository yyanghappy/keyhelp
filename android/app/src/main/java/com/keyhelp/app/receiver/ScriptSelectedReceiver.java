package com.keyhelp.app.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class ScriptSelectedReceiver extends BroadcastReceiver {
    private static final String TAG = "ScriptSelectedReceiver";
    private static ScriptSelectedListener listener;

    public interface ScriptSelectedListener {
        void onScriptSelected(String scriptId);
    }

    public static void setListener(ScriptSelectedListener l) {
        listener = l;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "onReceive called with action: " + intent.getAction());
        if ("com.keyhelp.app.SCRIPT_SELECTED".equals(intent.getAction())) {
            String scriptId = intent.getStringExtra("script_id");
            Log.d(TAG, "Script selected: " + scriptId);
            Log.d(TAG, "Listener is: " + (listener != null ? "not null" : "null"));

            if (listener != null && scriptId != null) {
                Log.d(TAG, "Calling listener.onScriptSelected");
                listener.onScriptSelected(scriptId);
                Log.d(TAG, "listener.onScriptSelected called successfully");
            } else {
                Log.d(TAG, "Listener is null or scriptId is null. listener=" + (listener != null) + ", scriptId=" + scriptId);
            }
        } else {
            Log.d(TAG, "Received unexpected action: " + intent.getAction());
        }
    }
}