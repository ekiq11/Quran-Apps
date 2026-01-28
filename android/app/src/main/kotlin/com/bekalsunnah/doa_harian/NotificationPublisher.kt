// android/app/src/main/kotlin/com/bekalsunnah/doa_harian/NotificationPublisher.kt
// ✅ SHOWS NOTIFICATION AT SCHEDULED TIME - Persistent like WhatsApp

package com.bekalsunnah.doa_harian

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class NotificationPublisher : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotificationPublisher"
        const val NOTIFICATION_ID = "notification_id"
        const val NOTIFICATION_TITLE = "notification_title"
        const val NOTIFICATION_BODY = "notification_body"
        const val NOTIFICATION_CHANNEL = "notification_channel"
        const val NOTIFICATION_TYPE = "notification_type"
        const val NOTIFICATION_PAYLOAD = "notification_payload"
        const val NOTIFICATION_SOUND = "notification_sound"
        const val NOTIFICATION_VIBRATE = "notification_vibrate"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "🔔 NotificationPublisher triggered")
        
        try {
            val notificationId = intent.getIntExtra(NOTIFICATION_ID, 0)
            val title = intent.getStringExtra(NOTIFICATION_TITLE) ?: "Bekal Muslim"
            val body = intent.getStringExtra(NOTIFICATION_BODY) ?: ""
            val channel = intent.getStringExtra(NOTIFICATION_CHANNEL) ?: "default"
            val type = intent.getIntExtra(NOTIFICATION_TYPE, 9)
            val payload = intent.getStringExtra(NOTIFICATION_PAYLOAD) ?: ""
            val playSound = intent.getBooleanExtra(NOTIFICATION_SOUND, true)
            val vibrate = intent.getBooleanExtra(NOTIFICATION_VIBRATE, true)
            
            Log.d(TAG, "📱 Showing notification: $title")
            
            // ✅ SHOW NOTIFICATION
            showNotification(
                context = context,
                id = notificationId,
                title = title,
                body = body,
                channel = channel,
                type = type,
                payload = payload,
                playSound = playSound,
                vibrate = vibrate
            )
            
            // ✅ SAVE TO HISTORY via NotificationReceiver
            val receiverIntent = Intent(context, NotificationReceiver::class.java).apply {
                putExtra("notification_id", "${notificationId}_${System.currentTimeMillis()}")
                putExtra("notification_title", title)
                putExtra("notification_body", body)
                putExtra("notification_type", type)
            }
            context.sendBroadcast(receiverIntent)
            
            Log.d(TAG, "✅ Notification shown successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing notification: ${e.message}", e)
        }
    }
    
    private fun showNotification(
        context: Context,
        id: Int,
        title: String,
        body: String,
        channel: String,
        type: Int,
        payload: String,
        playSound: Boolean,
        vibrate: Boolean
    ) {
        // Create notification channel (Android 8.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel(context, channel)
        }
        
        // Create intent for when notification is tapped
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("notification_payload", payload)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build notification
        val builder = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false) // ✅ DON'T auto-dismiss (like WhatsApp)
            .setOnlyAlertOnce(false)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
        
        // ✅ SOUND
        if (playSound) {
            val soundUri = getSoundUri(context, type)
            builder.setSound(soundUri)
        }
        
        // ✅ VIBRATION
        if (vibrate) {
            builder.setVibrate(longArrayOf(0, 500, 200, 500))
        }
        
        // ✅ LED LIGHT
        builder.setLights(getColorForType(type), 1000, 3000)
        
        // Show notification
        with(NotificationManagerCompat.from(context)) {
            notify(id, builder.build())
        }
    }
    
    private fun createNotificationChannel(context: Context, channelId: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = when (channelId) {
                "prayer_critical_v10" -> "Adzan & Waktu Sholat"
                "dzikir_critical_v10" -> "Pengingat Dzikir"
                "tilawah_critical_v10" -> "Pengingat Tilawah"
                "doa_critical_v10" -> "Pengingat Doa"
                else -> "Bekal Muslim"
            }
            
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(channelId, name, importance).apply {
                description = "Notifikasi ibadah harian"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun getSoundUri(context: Context, type: Int): Uri {
        return when (type) {
            in 0..4 -> { // Prayer times
                try {
                    Uri.parse("android.resource://${context.packageName}/raw/adzan")
                } catch (e: Exception) {
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                }
            }
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
    }
    
    private fun getColorForType(type: Int): Int {
        return when (type) {
            0 -> 0xFF8B5CF6.toInt() // Subuh - Purple
            1 -> 0xFFF59E0B.toInt() // Dzuhur - Amber
            2 -> 0xFFEF4444.toInt() // Ashar - Red
            3 -> 0xFFEC4899.toInt() // Maghrib - Pink
            4 -> 0xFF3B82F6.toInt() // Isya - Blue
            7 -> 0xFF06B6D4.toInt() // Dzikir - Cyan
            8 -> 0xFF10B981.toInt() // Tilawah - Green
            10 -> 0xFFA855F7.toInt() // Doa - Purple
            else -> 0xFF059669.toInt() // Default - Green
        }
    }
}