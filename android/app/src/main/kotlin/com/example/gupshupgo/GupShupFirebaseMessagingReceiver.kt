package com.gupshupgo.app

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.util.Log
import com.hiennv.flutter_callkit_incoming.CallkitIncomingBroadcastReceiver
import com.hiennv.flutter_callkit_incoming.Data
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver

/**
 * Displays incoming calls directly from the FCM broadcast, before Flutter's
 * background isolate has to boot.
 *
 * Starting a Dart isolate is reliable for ordinary background work, but it is
 * too fragile and too slow for a ringing call on killed/low-memory processes
 * and on aggressive OEM builds. This receiver keeps FlutterFire's normal
 * delivery path by delegating to [FlutterFirebaseMessagingReceiver] after the
 * native call UI has been posted.
 */
class GupShupFirebaseMessagingReceiver : FlutterFirebaseMessagingReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val extras = intent.extras
            val messageType = extras?.getString("type").orEmpty()
            // Preserve Flutter's proven foreground path. Rendering CallKit from
            // this receiver as well as from Dart can race on older Android/MIUI
            // builds. Native-first handling is only needed when the app cannot
            // render the call itself (background, locked, or terminated).
            if ((messageType == "incoming_call" || messageType == "call") &&
                !isApplicationForeground(context)
            ) {
                showIncomingCall(context, intent)
            }
        } catch (error: Exception) {
            // Never prevent FlutterFire from receiving the message. The Dart
            // handler remains a fallback on platforms/states where it can run.
            Log.e(TAG, "Unable to show native incoming-call notification", error)
        }

        super.onReceive(context, intent)
    }

    private fun isApplicationForeground(context: Context): Boolean {
        val keyguardManager =
            context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        if (keyguardManager?.isKeyguardLocked == true) return false

        val activityManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                ?: return false
        val packageName = context.packageName
        return activityManager.runningAppProcesses?.any { process ->
            process.importance ==
                ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                process.processName == packageName
        } == true
    }

    private fun showIncomingCall(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        val channelId = extras.getString("channelId").orEmpty()
        if (channelId.isEmpty()) return

        // Ignore a stale token left by a different account on this install.
        // FCMService mirrors the active uid into Flutter's SharedPreferences.
        val expectedUserId = extras.getString("calleeId").orEmpty()
        val preferences = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val activeUserId = preferences.getString(ACTIVE_USER_KEY, null)
        if (!activeUserId.isNullOrEmpty() &&
            expectedUserId.isNotEmpty() &&
            activeUserId != expectedUserId
        ) {
            Log.w(TAG, "Ignoring incoming call for a different signed-in user")
            return
        }

        val callerId = extras.getString("callerId").orEmpty()
        val callerName = extras.getString("callerName")
            ?.takeIf { it.isNotBlank() }
            ?: callerId.ifBlank { "Unknown" }
        val callerPhotoUrl = extras.getString("callerPhotoUrl").orEmpty()
        val isAudioOnly = extras.getString("isAudioOnly") == "true"

        val callData = hashMapOf<String, Any?>(
            "id" to channelId,
            "nameCaller" to callerName,
            "appName" to "GupShupGo",
            "avatar" to callerPhotoUrl,
            "handle" to if (isAudioOnly) "Audio Call" else "Video Call",
            "type" to if (isAudioOnly) 0 else 1,
            "duration" to 45_000L,
            "textAccept" to "Accept",
            "textDecline" to "Decline",
            "extra" to hashMapOf<String, Any?>(
                "callerId" to callerId,
                "channelId" to channelId,
                "isAudioOnly" to isAudioOnly.toString(),
            ),
            "missedCallNotification" to hashMapOf<String, Any?>(
                "showNotification" to true,
                "isShowCallback" to true,
                "subtitle" to "Missed call",
                "callbackText" to "Call back",
            ),
            "android" to hashMapOf<String, Any?>(
                "isCustomNotification" to false,
                "isShowLogo" to false,
                "ringtonePath" to "system_ringtone_default",
                "backgroundColor" to "#00A884",
                "actionColor" to "#00A884",
                "incomingCallNotificationChannelName" to "Incoming Calls",
                "isShowCallID" to false,
                "isShowFullLockedScreen" to true,
                "isImportant" to true,
            ),
        )

        val data = Data(callData).apply { from = "notification" }
        context.sendBroadcast(
            CallkitIncomingBroadcastReceiver.getIntentIncoming(
                context,
                data.toBundle(),
            ),
        )
    }

    private companion object {
        const val TAG = "GupShupCallReceiver"
        const val ACTIVE_USER_KEY = "flutter.gsg_native_call_user_id"
    }
}
