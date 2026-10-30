package com.gupshupgo.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONArray
import org.json.JSONObject

/** One native owner for ringing, terminal tombstones and the durable Accept inbox. */
object NativeCalls {
    const val CHANNEL = "native_incoming_calls_v1"
    const val BRIDGE = "com.gupshupgo.app/native_calls"
    const val ID = "channelId"
    private const val NOTIFICATION_ID = 7310
    private val handler = Handler(Looper.getMainLooper())
    private val listeners = mutableMapOf<String, ListenerRegistration>()
    private val timers = mutableMapOf<String, Runnable>()
    // Process-local: an evicted RTC process must not leave the next call permanently busy.
    var activeRtcCall: String? = null

    fun prefs(context: Context) = context.getSharedPreferences("native_calls_v1", Context.MODE_PRIVATE)
    fun user(context: Context) = prefs(context).getString("userId", null)
    fun device(context: Context) = prefs(context).getString("deviceId", null)
    fun isCallMessage(data: Map<String, String>) = data["type"] in
        setOf("call", "incoming_call", "call_cancelled", "call_cancel")

    @Synchronized
    fun registration(context: Context): CallRegistrationState {
        val stored = prefs(context)
        return CallRegistrationState(user(context), device(context), stored.getString("token", null),
            stored.getString("registeredToken", null), stored.getLong("registrationGeneration", 0))
    }

    private fun saveRegistration(context: Context, state: CallRegistrationState) {
        prefs(context).edit().putString("userId", state.userId).putString("deviceId", state.deviceId)
            .putString("token", state.token).putString("registeredToken", state.registeredToken)
            .putLong("registrationGeneration", state.generation).commit()
    }

    @Synchronized
    fun observeToken(context: Context, token: String) {
        saveRegistration(context, registration(context).observeToken(token))
    }

    @Synchronized
    fun prepareRegistration(context: Context, expected: CallRegistrationState, token: String): CallRegistrationState? {
        val current = registration(context)
        if (!current.isBound(FirebaseAuth.getInstance().currentUser?.uid) || !current.sameAttempt(expected)) return null
        return current.observeToken(token).also { saveRegistration(context, it) }
    }

    @Synchronized
    fun confirmRegistration(context: Context, attempt: CallRegistrationState): Boolean {
        val confirmed = registration(context).confirm(attempt, FirebaseAuth.getInstance().currentUser?.uid) ?: return false
        saveRegistration(context, confirmed)
        return true
    }

    @Synchronized
    fun isRegistered(context: Context) = registration(context).isRegistered(FirebaseAuth.getInstance().currentUser?.uid)

    @Synchronized
    fun bind(context: Context, uid: String, deviceId: String) {
        require(FirebaseAuth.getInstance().currentUser?.uid == uid)
        require(CallPolicy.validId(deviceId))
        if (user(context) != uid || device(context) != deviceId) clear(context)
        saveRegistration(context, registration(context).bind(uid, deviceId))
        NativeCallWorker.syncToken(context)
    }

    @Synchronized
    fun clear(context: Context) {
        records(context).forEach { finish(context, it.optString(ID), "signed_out") }
        saveRegistration(context, registration(context).clear())
        prefs(context).edit().remove("pending").commit()
    }

    @Synchronized
    fun receive(context: Context, message: RemoteMessage) {
        val data = message.data
        val id = data[ID].orEmpty()
        if (!CallPolicy.validId(id)) return
        val uid = user(context)
        if (uid == null || uid != FirebaseAuth.getInstance().currentUser?.uid || uid != data["calleeId"]) {
            log(context, id, "wrong_account")
            return
        }
        prune(context)
        if (data["type"] in setOf("call_cancel", "call_cancelled")) {
            if (data["status"] == "answered" && data["acceptedDeviceId"] == device(context) &&
                record(context, id)?.optString("state") in setOf("accepted", "connected")) return
            finish(context, id, "cancelled")
            return
        }
        val expires = CallPolicy.expiresAt(data, message.sentTime) ?: return
        if (!CallPolicy.canRing(System.currentTimeMillis(), expires, prefs(context).contains("call:$id"))) {
            log(context, id, "duplicate_or_expired")
            return
        }
        if (activeRtcCall != null || records(context).any { it.optString("state") in setOf("ringing", "accepted") }) {
            finish(context, id, "busy")
            // Other signed-in devices may still answer; busy is device-local.
            return
        }
        val call = JSONObject(data as Map<*, *>).put("expiresAt", expires).put("state", "ringing")
        save(context, call)
        try {
            createChannel(context)
            if (!CallReadiness.notificationsEnabled(context)) {
                finish(context, id, "notifications_disabled")
                return
            }
            show(context, call)
            log(context, id, "notification_posted")
            NativeCallWorker.receipt(context, id, "notification_posted")
            watch(context, call)
            val timeout = Runnable { expire(context, id) }
            timers[id] = timeout
            handler.postDelayed(timeout, (expires - System.currentTimeMillis()).coerceAtLeast(1))
            // Backstop survives eviction. API 26+ also has OS notification timeout.
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT < 26) {
                // Android 7 has no Notification.setTimeoutAfter. Exact alarms did
                // not require special access on these versions.
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, expires, actionIntent(context, id, "timeout"))
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, expires, actionIntent(context, id, "timeout"))
            }
        } catch (error: Exception) {
            finish(context, id, "presentation_failed")
            Log.e("NativeCalls", "Call presentation failed", error)
        }
    }

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL, "Incoming calls", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Incoming voice and video calls"
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE).build())
            })
    }

    private fun activityIntent(context: Context, id: String, accept: Boolean): PendingIntent {
        val intent = Intent(context, NativeIncomingCallActivity::class.java)
            .setData(Uri.parse("gsg-call://$id/${if (accept) "accept" else "show"}"))
            .putExtra(ID, id).putExtra("accept", accept)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun actionIntent(context: Context, id: String, action: String): PendingIntent =
        PendingIntent.getBroadcast(context, 0,
            Intent(context, NativeCallActionReceiver::class.java)
                .setData(Uri.parse("gsg-call://$id/$action")).putExtra(ID, id).putExtra("action", action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun show(context: Context, call: JSONObject) {
        val id = call.getString(ID)
        val name = call.optString("callerName").ifBlank { "Incoming caller" }.take(120)
        val audioOnly = call.optString("isAudioOnly") == "true"
        val person = Person.Builder().setName(name).setImportant(true).build()
        val builder = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_call_notification)
            .setContentTitle(name).setContentText(if (audioOnly) "Incoming voice call" else "Incoming video call")
            .setCategory(NotificationCompat.CATEGORY_CALL).setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC).setOngoing(true).setAutoCancel(false)
            .setContentIntent(activityIntent(context, id, false))
            .setFullScreenIntent(activityIntent(context, id, false), true)
            .setStyle(NotificationCompat.CallStyle.forIncomingCall(person,
                actionIntent(context, id, "decline"), activityIntent(context, id, true)).setIsVideo(!audioOnly))
            .setTimeoutAfter((call.getLong("expiresAt") - System.currentTimeMillis()).coerceAtLeast(1))
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE))
            .setVibrate(longArrayOf(0, 700, 500, 700))
        val notification = builder.build().apply { flags = flags or Notification.FLAG_INSISTENT }
        // CallStyle is native on API 31+, compat actions on API 24-30.
        NotificationManagerCompat.from(context).notify(id, NOTIFICATION_ID, notification)
    }

    private fun watch(context: Context, call: JSONObject) {
        val id = call.getString(ID)
        listeners[id] = FirebaseFirestore.getInstance().collection("calls").document(id)
            .addSnapshotListener { snapshot, error ->
                if (error != null) { log(context, id, "status_listener_unavailable"); return@addSnapshotListener }
                if (snapshot == null || snapshot.metadata.isFromCache) return@addSnapshotListener
                val status = snapshot.getString("status")
                val ownAnswer = status == "answered" && snapshot.getString("acceptedDeviceId") == device(context)
                if (!snapshot.exists() || (!ownAnswer && status != "ringing")) finish(context, id, "cancelled")
            }
    }

    @Synchronized
    fun accept(context: Context, id: String): Boolean {
        val call = record(context, id) ?: return false
        if (call.optString("state") != "ringing" || call.optLong("expiresAt") <= System.currentTimeMillis() ||
            call.optString("calleeId") != user(context) || user(context) != FirebaseAuth.getInstance().currentUser?.uid) return false
        stopPresentation(context, id)
        call.put("state", "accepted").put("acceptedAt", System.currentTimeMillis())
        save(context, call)
        prefs(context).edit().putString("pending", id).commit()
        log(context, id, "accept_tapped")
        return true
    }

    @Synchronized
    fun pending(context: Context): Map<String, String>? {
        val id = prefs(context).getString("pending", null) ?: return null
        val call = record(context, id) ?: return null
        if (call.optString("state") != "accepted" || call.optString("calleeId") != user(context) ||
            user(context) != FirebaseAuth.getInstance().currentUser?.uid ||
            System.currentTimeMillis() - call.optLong("acceptedAt") > 90_000) {
            finish(context, id, "handoff_expired")
            return null
        }
        return call.keys().asSequence().associateWith { call.optString(it) } + ("deviceId" to device(context).orEmpty())
    }

    @Synchronized
    fun acknowledge(context: Context, id: String) {
        if (prefs(context).getString("pending", null) == id) prefs(context).edit().remove("pending").commit()
        record(context, id)?.let { save(context, it.put("state", "connected")) }
        log(context, id, "flutter_handoff")
    }

    fun decline(context: Context, id: String) {
        if (record(context, id)?.optString("state") != "ringing") return
        finish(context, id, "declined")
        NativeCallWorker.action(context, id, "declined")
    }

    fun expire(context: Context, id: String) {
        val call = record(context, id) ?: return
        if (call.optString("state") != "ringing" || call.optLong("expiresAt") > System.currentTimeMillis()) return
        finish(context, id, "missed")
        NativeCallWorker.action(context, id, "missed")
    }

    @Synchronized
    fun finish(context: Context, id: String, reason: String) {
        if (!CallPolicy.validId(id)) return
        stopPresentation(context, id)
        val call = record(context, id) ?: JSONObject().put(ID, id)
        save(context, call.put("state", reason).put("finishedAt", System.currentTimeMillis()))
        if (prefs(context).getString("pending", null) == id) prefs(context).edit().remove("pending").commit()
        log(context, id, reason)
        if (activeRtcCall == id) activeRtcCall = null
    }

    private fun stopPresentation(context: Context, id: String) {
        NotificationManagerCompat.from(context).cancel(id, NOTIFICATION_ID)
        listeners.remove(id)?.remove()
        timers.remove(id)?.let { handler.removeCallbacks(it) }
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(actionIntent(context, id, "timeout"))
    }

    fun record(context: Context, id: String): JSONObject? = prefs(context).getString("call:$id", null)
        ?.let { runCatching { JSONObject(it) }.getOrNull() }
    private fun records(context: Context) = prefs(context).all.keys.filter { it.startsWith("call:") }
        .mapNotNull { record(context, it.removePrefix("call:")) }
    private fun save(context: Context, call: JSONObject) {
        prefs(context).edit().putString("call:${call.getString(ID)}", call.toString()).commit()
    }
    private fun prune(context: Context) {
        val now = System.currentTimeMillis()
        records(context).forEach {
            val age = now - it.optLong("finishedAt", it.optLong("expiresAt"))
            if (age > CallPolicy.TOMBSTONE_MS) prefs(context).edit().remove("call:${it.getString(ID)}").commit()
            else if (it.optString("state") == "ringing" && it.optLong("expiresAt") <= now) expire(context, it.getString(ID))
            else if (it.optString("state") == "accepted" && now - it.optLong("acceptedAt") > 90_000)
                finish(context, it.getString(ID), "handoff_expired")
        }
    }
    @Synchronized
    fun log(context: Context, id: String, event: String) {
        Log.i("NativeCalls", "$event call=$id")
        val old = runCatching { JSONArray(prefs(context).getString("events", "[]")) }.getOrDefault(JSONArray())
        val events = JSONArray()
        for (i in maxOf(0, old.length() - 99) until old.length()) events.put(old.get(i))
        events.put(JSONObject().put("callId", id).put("event", event).put("at", System.currentTimeMillis()))
        prefs(context).edit().putString("events", events.toString()).apply()
    }
}
