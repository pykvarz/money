package com.expensebook.expense_book

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class BankNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotificationListener"
        private const val CHANNEL = "com.expensebook.expense_book/notification_parser"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        
        // Get dynamic set of bank packages from SharedPreferences
        val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
        val allowedPackages = prefs.getStringSet("bank_packages", setOf()) ?: setOf()
        
        // Filter by package name
        if (!allowedPackages.contains(packageName)) {
            return
        }
        
        // Check if this bank is enabled in settings
        val isEnabled = prefs.getBoolean("enable_$packageName", false)
        
        if (!isEnabled) {
            Log.d(TAG, "Bank $packageName is disabled in settings")
            return
        }
        
        // Extract notification text
        val notification = sbn.notification
        val extras = notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getString("android.text") ?: ""
        val bigText = extras.getString("android.bigText") ?: text
        
        val fullText = "$title\n$bigText".trim()
        
        Log.d(TAG, "Received notification from $packageName: $fullText")
        
        // Send to Flutter via method channel
        sendToFlutter(packageName, fullText)
    }

    private fun sendToFlutter(packageName: String, text: String) {
        try {
            // Create a background Flutter engine to communicate
            val intent = Intent(this, MainActivity::class.java)
            intent.action = "NOTIFICATION_RECEIVED"
            intent.putExtra("packageName", packageName)
            intent.putExtra("text", text)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send to Flutter: ${e.message}", e)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "NotificationListener disconnected")
    }
}
