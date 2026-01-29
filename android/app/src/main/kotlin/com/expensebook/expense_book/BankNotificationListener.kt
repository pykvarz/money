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
        private const val PREFS_NAME = "notification_settings"
        private const val CUSTOM_BANKS_KEY = "custom_banks"
        
        // Default bank package names (empty - user adds their own banks)
        private val DEFAULT_PACKAGES = emptySet<String>()
    }
    
    private fun getAllowedPackages(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        
        // Get custom banks from SharedPreferences (comma-separated)
        val customBanksStr = prefs.getString(CUSTOM_BANKS_KEY, "")
        val customBanks = if (customBanksStr.isNullOrEmpty()) {
            emptySet()
        } else {
            customBanksStr.split(",").toSet()
        }
        
        // Combine default and custom banks
        return DEFAULT_PACKAGES + customBanks
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        
        // Filter by package name (using dynamic list)
        if (!getAllowedPackages().contains(packageName)) {
            return
        }
        
        // Check if this bank is enabled in settings
        val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
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
