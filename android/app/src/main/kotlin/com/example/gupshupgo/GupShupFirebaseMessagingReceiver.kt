package com.gupshupgo.app

import android.content.Context
import android.content.Intent
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver

/** Calls never boot a Dart isolate, in any application state. */
class GupShupFirebaseMessagingReceiver : FlutterFirebaseMessagingReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras
        if (extras != null) {
            val message = RemoteMessage(extras)
            if (NativeCalls.isCallMessage(message.data)) {
                NativeCalls.receive(context.applicationContext, message)
                return
            }
        }
        super.onReceive(context, intent)
    }
}
