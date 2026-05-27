package com.bekalsunnah.doa_harian

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTimeWidgetProvider : HomeWidgetProvider() {

    // Prayer names used as keys to identify the active prayer
    private val prayerIds = mapOf(
        "Subuh"   to R.id.item_subuh,
        "Dzuhur"  to R.id.item_dzuhur,
        "Ashar"   to R.id.item_ashar,
        "Maghrib" to R.id.item_maghrib,
        "Isya"    to R.id.item_isya,
    )

    private val prayerTimeIds = mapOf(
        "Subuh"   to R.id.tv_subuh,
        "Dzuhur"  to R.id.tv_dzuhur,
        "Ashar"   to R.id.tv_ashar,
        "Maghrib" to R.id.tv_maghrib,
        "Isya"    to R.id.tv_isya,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_time)

            // ── Header ────────────────────────────────────────────
            val locationName = widgetData.getString("widget_location",    "Lokasi Anda") ?: "Lokasi Anda"
            val hijriDate    = widgetData.getString("widget_hijri",        "")            ?: ""
            val nextPrayer   = widgetData.getString("widget_prayer_name",  "Sholat")      ?: "Sholat"
            val nextTime     = widgetData.getString("widget_prayer_time",  "--:--")       ?: "--:--"
            val countdown    = widgetData.getString("widget_countdown",    "Menunggu...") ?: "Menunggu..."

            views.setTextViewText(R.id.tv_location,         locationName)
            views.setTextViewText(R.id.tv_hijri_date,       hijriDate)
            views.setTextViewText(R.id.tv_next_prayer_name, nextPrayer)
            views.setTextViewText(R.id.tv_next_prayer_time, nextTime)
            views.setTextViewText(R.id.tv_countdown,        "⏱ $countdown")

            // ── Last Read Surah ───────────────────────────────────
            val lastReadSurah = widgetData.getString("widget_last_read_surah", "Belum ada data") ?: "Belum ada data"
            val lastReadAyah  = widgetData.getString("widget_last_read_ayah",  "-") ?: "-"
            views.setTextViewText(R.id.tv_last_read_surah, lastReadSurah)
            views.setTextViewText(R.id.tv_last_read_ayah, lastReadAyah)

            // ── 5 Prayer times ────────────────────────────────────
            val subuhTime   = widgetData.getString("widget_subuh",   "--:--") ?: "--:--"
            val dzuhurTime  = widgetData.getString("widget_dzuhur",  "--:--") ?: "--:--"
            val asharTime   = widgetData.getString("widget_ashar",   "--:--") ?: "--:--"
            val maghribTime = widgetData.getString("widget_maghrib", "--:--") ?: "--:--"
            val isyaTime    = widgetData.getString("widget_isya",    "--:--") ?: "--:--"

            views.setTextViewText(R.id.tv_subuh,   subuhTime)
            views.setTextViewText(R.id.tv_dzuhur,  dzuhurTime)
            views.setTextViewText(R.id.tv_ashar,   asharTime)
            views.setTextViewText(R.id.tv_maghrib, maghribTime)
            views.setTextViewText(R.id.tv_isya,    isyaTime)

            // ── Highlight active prayer ───────────────────────────
            // Reset all to normal background first
            for ((_, itemId) in prayerIds) {
                views.setInt(itemId, "setBackgroundResource", R.drawable.widget_prayer_item_bg)
            }
            for ((_, tvId) in prayerTimeIds) {
                views.setTextColor(tvId, Color.parseColor("#FFFFFF"))
            }

            // Apply active highlight
            val activePrayerItemId = prayerIds[nextPrayer]
            val activePrayerTvId   = prayerTimeIds[nextPrayer]
            if (activePrayerItemId != null) {
                views.setInt(activePrayerItemId, "setBackgroundResource", R.drawable.widget_active_prayer_bg)
            }
            if (activePrayerTvId != null) {
                views.setTextColor(activePrayerTvId, Color.parseColor("#34D399"))
            }

            // ── Open app on tap ────────────────────────────────────
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, launchIntent,
                    android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
