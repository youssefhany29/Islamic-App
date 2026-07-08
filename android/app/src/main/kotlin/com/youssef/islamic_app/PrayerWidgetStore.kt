package com.youssef.islamic_app

import android.content.Context

object PrayerWidgetStore {
    private const val PREFS = "prayer_widget_snapshot"
    private const val LIVE_STATUS_ENABLED = "prayer_live_status_enabled"

    fun save(context: Context, values: Map<String, Any?>) {
        val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        for ((key, value) in values) {
            when (value) {
                is String -> editor.putString(key, value)
                is Boolean -> editor.putBoolean(key, value)
                is Int -> editor.putLong(key, value.toLong())
                is Long -> editor.putLong(key, value)
                is Double -> editor.putLong(key, value.toLong())
                null -> Unit
            }
        }
        editor.apply()
    }

    fun read(context: Context): PrayerWidgetSnapshot {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return PrayerWidgetSnapshot(
            prayerName = prefs.getString("prayerName", null) ?: "الصلاة",
            prayerKey = prefs.getString("prayerKey", null) ?: "maghrib",
            timeText = prefs.getString("timeText", null) ?: "--:--",
            remainingText = prefs.getString("remainingText", null) ?: "--:--:--",
            locationLabel = prefs.getString("locationLabel", null) ?: "موقعك",
            backgroundAsset = prefs.getString("backgroundAsset", null) ?: "",
            backgroundFilePath = prefs.getString("backgroundFilePath", null) ?: "",
            updatedAtMillis = prefs.getLong("updatedAtMillis", 0L),
            nextPrayerAtMillis = prefs.getLong("nextPrayerAtMillis", 0L),
            followingPrayerName = prefs.getString("followingPrayerName", null) ?: "—",
            followingPrayerTime = prefs.getString("followingPrayerTime", null) ?: "—",
            isLoading = prefs.getBoolean("isLoading", false),
            hasData = prefs.getBoolean("hasData", false),
        )
    }

    fun setLiveStatusEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(LIVE_STATUS_ENABLED, enabled)
            .apply()
    }

    fun isLiveStatusEnabled(context: Context): Boolean {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(LIVE_STATUS_ENABLED, false)
    }
}
