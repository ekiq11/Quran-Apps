package com.bekalsunnah.doa_harian

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import android.util.Log

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "BekalMuslimMainActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "MainActivity onCreate called")
        
        setupFullScreenNotifications()
        handleNotificationIntent(intent)
    }
    
    private fun setupFullScreenNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }
    
    private fun handleNotificationIntent(intent: Intent?) {
        if (intent == null) return
        
        val action = intent.action
        if (action == "FLUTTER_NOTIFICATION_CLICK") {
            Log.d(TAG, "Notification tapped")
        }
    }
}