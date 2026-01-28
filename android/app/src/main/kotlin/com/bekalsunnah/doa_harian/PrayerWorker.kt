package com.bekalsunnah.doa_harian

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class PrayerWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    
    companion object {
        private const val TAG = "PrayerWorker"
    }
    
    override fun doWork(): Result {
        Log.d(TAG, "🔄 Background work executing...")
        
        try {
            // ✅ Check if app needs to reschedule
            val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val needsReschedule = prefs.getBoolean("flutter.needs_reschedule", false)
            val lastSchedule = prefs.getLong("flutter.last_notification_schedule", 0)
            
            val now = System.currentTimeMillis()
            val hoursSinceLastSchedule = (now - lastSchedule) / (1000 * 60 * 60)
            
            if (needsReschedule || hoursSinceLastSchedule > 24) {
                Log.d(TAG, "⚠️ Notifications need rescheduling (hours since last: $hoursSinceLastSchedule)")
                
                // ✅ Trigger app to open dan reschedule
                try {
                    val launchIntent = applicationContext.packageManager
                        .getLaunchIntentForPackage(applicationContext.packageName)
                    
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        launchIntent.putExtra("trigger_reschedule", true)
                        applicationContext.startActivity(launchIntent)
                        
                        Log.d(TAG, "✅ App triggered for rescheduling")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error triggering app: ${e.message}")
                }
            } else {
                Log.d(TAG, "✅ Notifications still valid (scheduled $hoursSinceLastSchedule hours ago)")
            }
            
            return Result.success()
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in background work: ${e.message}")
            return Result.retry()
        }
    }
}