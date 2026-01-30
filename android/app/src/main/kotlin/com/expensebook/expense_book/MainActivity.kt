package com.expensebook.expense_book

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.expensebook.expense_book/notification_parser"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "addBankPackage" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
                        val packages = prefs.getStringSet("bank_packages", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
                        packages.add(packageName)
                        prefs.edit().putStringSet("bank_packages", packages).apply()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "removeBankPackage" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
                        val packages = prefs.getStringSet("bank_packages", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
                        packages.remove(packageName)
                        prefs.edit().putStringSet("bank_packages", packages).apply()
                        
                        // Also disable it
                        prefs.edit().remove("enable_$packageName").apply()
                        
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "getBankPackages" -> {
                    val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
                    val packages = prefs.getStringSet("bank_packages", setOf())?.toList() ?: listOf<String>()
                    result.success(packages)
                }
                "setBankEnabled" -> {
                    val packageName = call.argument<String>("packageName")
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    
                    if (packageName != null) {
                        val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
                        prefs.edit().putBoolean("enable_$packageName", enabled).apply()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "isBankEnabled" -> {
                    val packageName = call.argument<String>("packageName")
                    
                    if (packageName != null) {
                        val prefs = getSharedPreferences("notification_settings", MODE_PRIVATE)
                        val enabled = prefs.getBoolean("enable_$packageName", false)
                        result.success(enabled)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "openNotificationSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Handle notification received intent
        if (intent.action == "NOTIFICATION_RECEIVED") {
            val packageName = intent.getStringExtra("packageName")
            val text = intent.getStringExtra("text")
            
            if (packageName != null && text != null) {
                // Send to Flutter
                methodChannel?.invokeMethod("onNotificationReceived", mapOf(
                    "packageName" to packageName,
                    "text" to text
                ))
            }
        }
    }
}
