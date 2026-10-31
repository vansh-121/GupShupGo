package com.gupshupgo.app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import java.util.concurrent.atomic.AtomicBoolean

/** A native lock-screen Activity: presenting a call never starts Flutter. */
class NativeIncomingCallActivity : Activity() {
    private var callId = ""
    private val handler = Handler(Looper.getMainLooper())
    private val check = object : Runnable {
        override fun run() {
            NativeCalls.expire(applicationContext, callId)
            if (NativeCalls.record(applicationContext, callId)?.optString("state") != "ringing") finish()
            else handler.postDelayed(this, 500)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(true); setTurnScreenOn(true) }
        @Suppress("DEPRECATION")
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= 29) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
        showIntent(intent)
    }

    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); showIntent(intent) }

    private fun showIntent(intent: Intent) {
        handler.removeCallbacks(check)
        callId = intent.getStringExtra(NativeCalls.ID).orEmpty()
        val call = NativeCalls.record(this, callId)
        if (call == null || call.optString("state") != "ringing") { finish(); return }
        if (intent.getBooleanExtra("accept", false)) { accept(); return }
        setContentView(NativeIncomingCallView(
            context = this,
            callerName = call.optString("callerName").ifBlank { getString(R.string.native_call_unknown_caller) }.take(120),
            callerPhotoUrl = call.optString("callerPhotoUrl"),
            isAudioOnly = call.optString("isAudioOnly") == "true",
            onAccept = { accept() },
            onDecline = { NativeCalls.decline(applicationContext, callId); finish() },
        ))
        handler.post(check)
    }

    private fun accept() {
        // Use the same explicit destination as the notification's Answer action.
        // MainActivity validates and persists Accept before handing it to Flutter.
        startActivity(NativeCalls.acceptIntent(this, callId))
        finish()
    }

    override fun onDestroy() { handler.removeCallbacks(check); super.onDestroy() }
}

class NativeCallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(NativeCalls.ID).orEmpty()
        val pending = goAsync()
        val completed = AtomicBoolean(false)
        val finish = Runnable { if (completed.compareAndSet(false, true)) pending.finish() }
        val handler = Handler(Looper.getMainLooper())
        // Hold the receiver for the immediate native write; WorkManager retries offline.
        handler.postDelayed(finish, 8000)
        when (intent.getStringExtra("action")) {
            "decline" -> NativeCalls.decline(context.applicationContext, id)
            "timeout" -> NativeCalls.expire(context.applicationContext, id)
        }
        val event = if (intent.getStringExtra("action") == "decline") "declined" else "missed"
        if (NativeCalls.record(context, id)?.optString("state") != event) { finish.run(); return }
        NativeCallWorker.sendActionNow(context.applicationContext, id, event)?.addOnCompleteListener {
            handler.removeCallbacks(finish)
            finish.run()
        } ?: finish.run()
    }
}
