package com.youssef.islamic_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

object PrayerLiveStatusNotification {
    private const val CHANNEL_ID = "prayer_live_status"
    private const val NOTIFICATION_ID = 4202

    fun showOrUpdate(context: Context, snapshot: PrayerWidgetSnapshot) {
        if (!PrayerWidgetStore.isLiveStatusEnabled(context) || !snapshot.hasData) {
            cancel(context)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        createChannel(context)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("الصلاة القادمة: ${snapshot.prayerName}")
            .setContentText("${snapshot.timeText} · ${snapshot.locationLabel}")
            .setSubText("متبقي ${snapshot.remainingText}")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setContentIntent(PrayerWidgetProvider.prayerPendingIntent(context))
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Prayer live status",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the next prayer status when enabled."
            setShowBadge(false)
        }

        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}
