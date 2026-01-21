package com.keyhelp.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.keyhelp.app.AccessibilityMethodChannel
import com.keyhelp.app.FloatWindowMethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AccessibilityMethodChannel(flutterEngine, applicationContext)
        FloatWindowMethodChannel(flutterEngine, applicationContext)
    }
}

