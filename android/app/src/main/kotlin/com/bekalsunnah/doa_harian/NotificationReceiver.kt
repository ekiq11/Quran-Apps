// android/app/src/main/kotlin/com/bekalsunnah/doa_harian/NotificationReceiver.kt
// ✅ PERSISTENT NOTIFICATION HANDLER - Like WhatsApp

package com.bekalsunnah.doa_harian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject

class NotificationReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotificationReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_HISTORY = "flutter.notification_history_v3"
        private const val KEY_BADGE = "flutter.notification_badge_count"
        private const val KEY_READ = "flutter.read_notifications_v2"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📱 Notification received")
        
        try {
            val notificationId = intent.getStringExtra("notification_id")
            val title = intent.getStringExtra("notification_title")
            val body = intent.getStringExtra("notification_body")
            val type = intent.getIntExtra("notification_type", 9)
            
            if (notificationId == null || title == null || body == null) {
                Log.e(TAG, "❌ Missing notification data")
                return
            }
            
            Log.d(TAG, "✅ Saving notification: $title")
            
            // ✅ SAVE TO SHARED PREFERENCES (Like WhatsApp)
            saveNotificationToHistory(
                context = context,
                id = notificationId,
                title = title,
                body = body,
                type = type
            )
            
            // ✅ UPDATE BADGE COUNT
            updateBadgeCount(context)
            
            Log.d(TAG, "✅ Notification saved successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in NotificationReceiver: ${e.message}", e)
        }
    }
    
    private fun saveNotificationToHistory(
        context: Context,
        id: String,
        title: String,
        body: String,
        type: Int
    ) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val historyJson = prefs.getString(KEY_HISTORY, "[]") ?: "[]"
            
            // Parse existing history
            val historyArray = org.json.JSONArray(historyJson)
            
            // Check if already exists
            for (i in 0 until historyArray.length()) {
                val item = historyArray.getJSONObject(i)
                if (item.optString("id") == id) {
                    Log.d(TAG, "⚠️ Notification already in history: $id")
                    return
                }
            }
            
            // Create new notification object
            val notification = JSONObject().apply {
                put("id", id)
                put("title", title)
                put("body", body)
                put("type", type)
                put("timestamp", System.currentTimeMillis())
                put("isRead", false)
                put("isScheduled", false)
            }
            
            // Add to beginning of array
            val newArray = org.json.JSONArray()
            newArray.put(notification)
            for (i in 0 until historyArray.length()) {
                newArray.put(historyArray.get(i))
            }
            
            // Limit to 100 items
            val limitedArray = org.json.JSONArray()
            val limit = minOf(100, newArray.length())
            for (i in 0 until limit) {
                limitedArray.put(newArray.get(i))
            }
            
            // Save back to preferences
            prefs.edit().putString(KEY_HISTORY, limitedArray.toString()).apply()
            
            Log.d(TAG, "✅ Notification saved to history (Total: ${limitedArray.length()})")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error saving notification: ${e.message}", e)
        }
    }
    
    private fun updateBadgeCount(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val historyJson = prefs.getString(KEY_HISTORY, "[]") ?: "[]"
            val readIdsJson = prefs.getString(KEY_READ, "[]") ?: "[]"
            
            val historyArray = org.json.JSONArray(historyJson)
            val readIdsArray = org.json.JSONArray(readIdsJson)
            
            // Convert read IDs to set
            val readIds = mutableSetOf<String>()
            for (i in 0 until readIdsArray.length()) {
                readIds.add(readIdsArray.getString(i))
            }
            
            // Count unread notifications
            var unreadCount = 0
            for (i in 0 until historyArray.length()) {
                val item = historyArray.getJSONObject(i)
                val id = item.optString("id")
                val isScheduled = item.optBoolean("isScheduled", false)
                
                if (!isScheduled && !readIds.contains(id)) {
                    unreadCount++
                }
            }
            
            // Save badge count
            prefs.edit().putInt(KEY_BADGE, unreadCount).apply()
            
            Log.d(TAG, "📢 Badge count updated: $unreadCount")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error updating badge: ${e.message}", e)
        }
    }
}