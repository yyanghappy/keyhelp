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
        if ("com.keyhelp.app.SCRIPT_SELECTED".equals(intent.getAction())) {
            String scriptId = intent.getStringExtra("script_id");
            Log.d(TAG, "Script selected: " + scriptId);

            if (listener != null && scriptId != null) {
                listener.onScriptSelected(scriptId);
            }
        }
    }
}