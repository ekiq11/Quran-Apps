package com.bekalsunnah.doa_harian

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.work.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.bekalsunnah.doa_harian/battery"
    private val TAG = "MainActivity"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "🚀 MainActivity onCreate - Clean start")
        
        // ✅ REMOVED: requestBatteryOptimizationExemption()
        // ✅ REMOVED: setupPeriodicWork()
        // All permission requests moved to Flutter onboarding screen
        
        // ✅ Handle notification intent only
        handleNotificationIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "📬 onNewIntent received")
        handleNotificationIntent(intent)
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // ✅ Setup method channel for battery optimization
        // Flutter onboarding screen will call these methods when needed
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationDisabled" -> {
                    val isDisabled = isBatteryOptimizationDisabled()
                    Log.d(TAG, "📞 Flutter called: isBatteryOptimizationDisabled = $isDisabled")
                    result.success(isDisabled)
                }
                "requestBatteryOptimizationExemption" -> {
                    Log.d(TAG, "📞 Flutter called: requestBatteryOptimizationExemption")
                    val success = requestBatteryOptimizationExemption()
                    result.success(success)
                }
                "openBatteryOptimizationSettings" -> {
                    Log.d(TAG, "📞 Flutter called: openBatteryOptimizationSettings")
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "setupPeriodicWork" -> {
                    Log.d(TAG, "📞 Flutter called: setupPeriodicWork")
                    setupPeriodicWork()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        Log.d(TAG, "✅ FlutterEngine configured - method channel ready")
    }
    
    /**
     * ✅ CRITICAL: Setup periodic work untuk memastikan notifications selalu scheduled
     * Ini akan dipanggil oleh Flutter SETELAH onboarding, BUKAN saat startup
     */
    private fun setupPeriodicWork() {
        try {
            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(false)
                .setRequiresCharging(false)
                .build()
            
            val workRequest = PeriodicWorkRequestBuilder<PrayerWorker>(
                6, TimeUnit.HOURS  // Check setiap 6 jam
            )
                .setConstraints(constraints)
                .setInitialDelay(15, TimeUnit.MINUTES)  // Delay awal 15 menit
                .build()
            
            WorkManager.getInstance(applicationContext)
                .enqueueUniquePeriodicWork(
                    "PrayerNotificationScheduler",
                    ExistingPeriodicWorkPolicy.KEEP,
                    workRequest
                )
            
            Log.d(TAG, "✅ Periodic work scheduled (every 6 hours)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error setting up periodic work: ${e.message}")
        }
    }
    
    /**
     * ✅ Handle notification tap
     */
    private fun handleNotificationIntent(intent: Intent?) {
        if (intent == null) return
        
        val action = intent.action
        Log.d(TAG, "📱 Handling intent action: $action")
        
        if (action == "FLUTTER_NOTIFICATION_CLICK") {
            Log.d(TAG, "🔔 Notification clicked - app opening")
        }
    }
    
    /**
     * ✅ Check if battery optimization is disabled
     * Called ONLY when Flutter requests it via method channel
     */
    private fun isBatteryOptimizationDisabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val packageName = packageName
            val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
            
            // ✅ NO logging here to avoid spam in logcat
            return isIgnoring
        }
        return true
    }
    
    /**
     * ✅ Request battery optimization exemption
     * Called ONLY when Flutter requests it via method channel (during onboarding)
     */
    private fun requestBatteryOptimizationExemption(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val packageName = packageName
            
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                try {
                    Log.d(TAG, "⚡ Requesting battery optimization exemption...")
                    
                    val intent = Intent().apply {
                        action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        data = android.net.Uri.parse("package:$packageName")
                    }
                    
                    startActivity(intent)
                    return true
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error requesting battery exemption: ${e.message}")
                    return false
                }
            } else {
                Log.d(TAG, "✅ Battery optimization already disabled")
                return true
            }
        }
        return true
    }
    
    /**
     * ✅ Open battery optimization settings
     * Called ONLY when Flutter requests it via method channel
     */
    private fun openBatteryOptimizationSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Log.d(TAG, "🔧 Opening battery optimization settings...")
                
                val intent = Intent().apply {
                    action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                }
                
                startActivity(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening settings: ${e.message}")
        }
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "▶️ onResume - App is visible")
        
        // ✅ REMOVED: All permission checks
        // ✅ REMOVED: Battery optimization check logging
        // ✅ REMOVED: Exact alarm check logging
        // App just resumes normally without any checks
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "⏸️ onPause - App going to background")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "💥 onDestroy - App destroyed")
    }
}