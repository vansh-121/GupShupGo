package com.gupshupgo.app

import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.ConnectionResult

object CallReadiness {
    fun notificationsEnabled(context: Context): Boolean {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 26 ||
            (context.getSystemService(NotificationManager::class.java).getNotificationChannel(NativeCalls.CHANNEL)
                ?.importance ?: NotificationManager.IMPORTANCE_HIGH) != NotificationManager.IMPORTANCE_NONE
    }

    fun read(context: Context): Map<String, Any> {
        NativeCalls.createChannel(context)
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = if (Build.VERSION.SDK_INT >= 26) manager.getNotificationChannel(NativeCalls.CHANNEL) else null
        return mapOf(
            "notifications" to notificationsEnabled(context),
            "headsUp" to (channel == null || channel.importance >= NotificationManager.IMPORTANCE_HIGH),
            "ringtone" to (channel == null || channel.sound != null),
            "fullScreen" to (Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent()),
            "batteryUnrestricted" to context.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(context.packageName),
            "backgroundRestricted" to (Build.VERSION.SDK_INT >= 28 && context.getSystemService(ActivityManager::class.java).isBackgroundRestricted),
            "playServices" to (GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS),
            "xiaomi" to (Build.MANUFACTURER.lowercase() in setOf("xiaomi", "redmi", "poco")),
            "manufacturer" to Build.MANUFACTURER,
            "registered" to NativeCalls.isRegistered(context),
        )
    }

    fun open(activity: Activity, page: String): Boolean {
        val packageUri = Uri.parse("package:${activity.packageName}")
        val target = when (page) {
            "notifications" -> if (Build.VERSION.SDK_INT >= 26) Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName).putExtra(Settings.EXTRA_CHANNEL_ID, NativeCalls.CHANNEL)
                else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, packageUri)
                else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
            "battery" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            "autostart" -> Intent().setComponent(ComponentName("com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"))
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
        }
        return try { activity.startActivity(target); true } catch (_: Exception) {
            try { activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)); true }
            catch (_: Exception) { false }
        }
    }
}
