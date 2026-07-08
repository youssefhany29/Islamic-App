package com.youssef.islamic_app

import android.graphics.Color
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.Window
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPrayerDeepLink = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.youssef.islamic_app/prayer_widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncPrayerWidgetSnapshot" -> {
                    @Suppress("UNCHECKED_CAST")
                    val values = call.arguments as? Map<String, Any?>
                    if (values != null) {
                        PrayerWidgetStore.save(this, values)
                        PrayerWidgetProvider.updateAll(this)
                        PrayerLiveStatusNotification.showOrUpdate(
                            this,
                            PrayerWidgetStore.read(this),
                        )
                    }
                    result.success(null)
                }
                "setPrayerLiveStatusEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    PrayerWidgetStore.setLiveStatusEnabled(this, enabled)
                    if (enabled) {
                        PrayerLiveStatusNotification.showOrUpdate(
                            this,
                            PrayerWidgetStore.read(this),
                        )
                    } else {
                        PrayerLiveStatusNotification.cancel(this)
                    }
                    result.success(null)
                }
                "consumeInitialPrayerDeepLink" -> {
                    val shouldOpen = pendingPrayerDeepLink
                    pendingPrayerDeepLink = false
                    result.success(shouldOpen)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingPrayerDeepLink = isPrayerDeepLink(intent)
        forceBlackSystemBars()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingPrayerDeepLink = pendingPrayerDeepLink || isPrayerDeepLink(intent)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)

        if (hasFocus) {
            forceBlackSystemBars()
        }
    }

    private fun forceBlackSystemBars() {
        val currentWindow: Window = window

        currentWindow.statusBarColor = Color.BLACK
        currentWindow.navigationBarColor = Color.BLACK

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            currentWindow.decorView.systemUiVisibility =
                currentWindow.decorView.systemUiVisibility and
                        View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR.inv()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            currentWindow.decorView.systemUiVisibility =
                currentWindow.decorView.systemUiVisibility and
                        View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR.inv()
        }
    }

    private fun isPrayerDeepLink(intent: Intent?): Boolean {
        val uri: Uri = intent?.data ?: return false
        return uri.scheme == "islamicapp" && uri.host == "prayer"
    }
}
