package com.youssef.islamic_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val snapshot = PrayerWidgetStore.read(context)
        appWidgetIds.forEach { appWidgetId ->
            appWidgetManager.updateAppWidget(
                appWidgetId,
                buildRemoteViews(context, snapshot),
            )
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PrayerWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            val snapshot = PrayerWidgetStore.read(context)
            ids.forEach { id -> manager.updateAppWidget(id, buildRemoteViews(context, snapshot)) }
        }

        private fun buildRemoteViews(
            context: Context,
            snapshot: PrayerWidgetSnapshot,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            views.setTextViewText(R.id.prayer_widget_title, "الصلاة القادمة")
            views.setImageViewResource(R.id.prayer_widget_background, R.drawable.prayer_widget_hero_bg)

            if (snapshot.hasData) {
                views.setTextViewText(R.id.prayer_widget_location, snapshot.locationLabel)
                views.setTextViewText(R.id.prayer_widget_prayer_name, snapshot.prayerName)
                views.setTextViewText(R.id.prayer_widget_time, snapshot.timeText)
                views.setTextViewText(
                    R.id.prayer_widget_remaining,
                    "متبقي ${snapshot.remainingText}",
                )
                views.setTextViewText(
                    R.id.prayer_widget_following,
                    "الصلاة التالية: ${snapshot.followingPrayerName} ${snapshot.followingPrayerTime}",
                )
                views.setViewVisibility(R.id.prayer_widget_time, View.VISIBLE)
                views.setViewVisibility(R.id.prayer_widget_remaining, View.VISIBLE)
                views.setViewVisibility(R.id.prayer_widget_following, View.VISIBLE)
            } else {
                views.setTextViewText(R.id.prayer_widget_location, "موقعك")
                views.setTextViewText(
                    R.id.prayer_widget_prayer_name,
                    "افتح التطبيق لتحديث مواقيت الصلاة",
                )
                views.setTextViewText(R.id.prayer_widget_time, "")
                views.setTextViewText(R.id.prayer_widget_remaining, "")
                views.setTextViewText(R.id.prayer_widget_following, "")
                views.setViewVisibility(R.id.prayer_widget_time, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_remaining, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_following, View.GONE)
            }

            views.setOnClickPendingIntent(
                R.id.prayer_widget_root,
                prayerPendingIntent(context),
            )

            return views
        }

        fun prayerPendingIntent(context: Context): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("islamicapp://prayer")).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                4201,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
