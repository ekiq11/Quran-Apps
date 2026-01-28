package com.bekalsunnah.doa_harian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.*
import java.util.concurrent.TimeUnit

/**
 * ✅ BootReceiver - Reschedule notifications after device reboot
 * This ensures prayer time notifications continue working after restart
 */
class BootReceiver : BroadcastReceiver() {
    
    private val TAG = "BootReceiver"
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            Log.d(TAG, "📱 Device rebooted - rescheduling notifications...")
            
            // Reschedule periodic work
            setupPeriodicWork(context)
            
            // Note: Flutter notifications will be rescheduled automatically
            // when the app is opened for the first time after reboot
            Log.d(TAG, "✅ Periodic work rescheduled after reboot")
        }
    }
    
    /**
     * Setup periodic work to maintain notification scheduling
     */
    private fun setupPeriodicWork(context: Context) {
        try {
            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(false)
                .setRequiresCharging(false)
                .build()
            
            val workRequest = PeriodicWorkRequestBuilder<PrayerWorker>(
                6, TimeUnit.HOURS
            )
                .setConstraints(constraints)
                .setInitialDelay(5, TimeUnit.MINUTES)
                .build()
            
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                    "PrayerNotificationScheduler",
                    ExistingPeriodicWorkPolicy.REPLACE,
                    workRequest
                )
            
            Log.d(TAG, "✅ Periodic work scheduled (every 6 hours)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error setting up periodic work: ${e.message}")
        }
    }
}