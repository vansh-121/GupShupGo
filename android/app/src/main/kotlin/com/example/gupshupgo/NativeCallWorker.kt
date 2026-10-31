package com.gupshupgo.app

import android.content.Context
import android.os.Build
import androidx.work.*
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.SetOptions
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService
import java.util.concurrent.TimeUnit

/** Token rotation works without an engine or a Dart token-refresh listener. */
class GupShupMessagingService : FlutterFirebaseMessagingService() {
    override fun onNewToken(token: String) {
        NativeCalls.observeToken(this, token)
        NativeCallWorker.syncToken(this)
        super.onNewToken(token)
    }
}

/** Durable native work. Never writes a stale account or revives a call. */
class NativeCallWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val context = applicationContext
        val uid = inputData.getString("userId") ?: return Result.success()
        val deviceId = inputData.getString("deviceId") ?: return Result.success()
        fun stillBound() = NativeCalls.user(context) == uid && NativeCalls.device(context) == deviceId &&
            FirebaseAuth.getInstance().currentUser?.uid == uid
        if (!stillBound()) return Result.success()
        val db = FirebaseFirestore.getInstance()
        val kind = inputData.getString("kind")
        return try {
            if (kind == "token") {
                val expected = NativeCalls.registration(context)
                if (expected.userId != uid || expected.deviceId != deviceId) return Result.success()
                val token = Tasks.await(FirebaseMessaging.getInstance().token, 20, TimeUnit.SECONDS)
                if (!stillBound()) return Result.success()
                // A token callback or account switch may race with the token fetch.
                val attempt = NativeCalls.prepareRegistration(context, expected, token)
                    ?: return if (stillBound()) Result.retry() else Result.success()
                val ref = db.collection("users").document(uid).collection("devices").document(deviceId)
                Tasks.await(ref.set(mapOf(
                    "deviceId" to deviceId, "fcmToken" to token, "platform" to "android",
                    "nativeCallsVersion" to 1, "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
                    "tokenUpdatedAt" to FieldValue.serverTimestamp(), "lastSeenAt" to FieldValue.serverTimestamp(),
                ), SetOptions.merge()), 20, TimeUnit.SECONDS)
                // Firestore's set task completes after server acknowledgement, not a local cache write.
                // Never confirm an older token or a binding that changed during that write.
                if (!NativeCalls.confirmRegistration(context, attempt)) {
                    return if (stillBound()) Result.retry() else Result.success()
                }
                NativeCalls.log(context, "", "token_registered")
            } else {
                val id = inputData.getString("callId") ?: return Result.success()
                val event = inputData.getString("event") ?: return Result.success()
                val ref = db.collection("calls").document(id)
                Tasks.await(db.runTransaction { tx ->
                    val call = tx.get(ref)
                    if (!stillBound() || !call.exists() || call.getString("calleeId") != uid) return@runTransaction null
                    if (kind == "action" && call.getString("status") == "ringing") {
                        tx.update(ref, mapOf("status" to event, "endedAt" to FieldValue.serverTimestamp()))
                    }
                    tx.set(ref.collection("deliveryReceipts").document("${deviceId}_$event"), mapOf(
                        "deviceId" to deviceId, "event" to event,
                        "recordedAt" to FieldValue.serverTimestamp(),
                        "occurredAtMs" to inputData.getLong("occurredAt", 0),
                    ))
                    null
                }, 20, TimeUnit.SECONDS)
                NativeCalls.log(context, id, "${event}_synced")
            }
            Result.success()
        } catch (error: Exception) {
            val cause = generateSequence<Throwable>(error) { it.cause }.last()
            val firestoreError = generateSequence<Throwable>(error) { it.cause }
                .filterIsInstance<FirebaseFirestoreException>().firstOrNull()
            val code = firestoreError?.code?.name?.lowercase()
                ?: cause.javaClass.simpleName
            NativeCalls.log(context, inputData.getString("callId").orEmpty(), "${kind}_retry_$code")
            if (runAttemptCount < 8 && stillBound()) Result.retry() else Result.failure()
        }
    }

    companion object {
        fun syncToken(context: Context) = enqueue(context, "token", "", "")
        fun action(context: Context, id: String, event: String) {
            enqueue(context, "action", id, event)
            sendActionNow(context, id, event)
        }
        fun sendActionNow(context: Context, id: String, event: String): Task<Boolean>? {
            val uid = NativeCalls.user(context) ?: return null
            if (uid != FirebaseAuth.getInstance().currentUser?.uid) return null
            val db = FirebaseFirestore.getInstance()
            val ref = db.collection("calls").document(id)
            return db.runTransaction { tx ->
                val call = tx.get(ref)
                if (NativeCalls.user(context) != uid || FirebaseAuth.getInstance().currentUser?.uid != uid ||
                    call.getString("calleeId") != uid || call.getString("status") != "ringing") false
                else {
                    tx.update(ref, mapOf("status" to event, "endedAt" to FieldValue.serverTimestamp()))
                    true
                }
            }
        }
        fun receipt(context: Context, id: String, event: String) = enqueue(context, "receipt", id, event)
        private fun enqueue(context: Context, kind: String, id: String, event: String) {
            val uid = NativeCalls.user(context) ?: return
            val device = NativeCalls.device(context) ?: return
            val request = OneTimeWorkRequestBuilder<NativeCallWorker>()
                .setInputData(workDataOf("kind" to kind, "userId" to uid, "deviceId" to device,
                    "callId" to id, "event" to event, "occurredAt" to System.currentTimeMillis()))
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS).build()
            // Serialize refreshes; a rotation during an active write is not lost.
            WorkManager.getInstance(context).enqueueUniqueWork("native-$uid-$kind-$id-$event",
                if (kind == "token") ExistingWorkPolicy.APPEND_OR_REPLACE else ExistingWorkPolicy.KEEP, request)
        }
    }
}
