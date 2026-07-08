package com.youssef.islamic_app

data class PrayerWidgetSnapshot(
    val prayerName: String,
    val prayerKey: String,
    val timeText: String,
    val remainingText: String,
    val locationLabel: String,
    val backgroundAsset: String,
    val backgroundFilePath: String,
    val updatedAtMillis: Long,
    val nextPrayerAtMillis: Long,
    val followingPrayerName: String,
    val followingPrayerTime: String,
    val isLoading: Boolean,
    val hasData: Boolean,
) {
    companion object {
        fun fallback(): PrayerWidgetSnapshot {
            return PrayerWidgetSnapshot(
                prayerName = "الصلاة",
                prayerKey = "maghrib",
                timeText = "--:--",
                remainingText = "--:--:--",
                locationLabel = "موقعك",
                backgroundAsset = "",
                backgroundFilePath = "",
                updatedAtMillis = 0L,
                nextPrayerAtMillis = 0L,
                followingPrayerName = "—",
                followingPrayerTime = "—",
                isLoading = false,
                hasData = false,
            )
        }
    }
}
