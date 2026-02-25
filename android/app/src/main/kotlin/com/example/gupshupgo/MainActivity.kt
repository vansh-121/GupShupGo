package com.example.gupshupgo

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.gupshupgo/phone_verification"
    private val PHONE_HINT_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPhoneNumberHint" -> {
                    requestPhoneNumberHint(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestPhoneNumberHint(result: MethodChannel.Result) {
        pendingResult = result

        val request = GetPhoneNumberHintIntentRequest.builder().build()

        Identity.getSignInClient(this)
            .getPhoneNumberHintIntent(request)
            .addOnSuccessListener { pendingIntent ->
                try {
                    startIntentSenderForResult(
                        pendingIntent.intentSender,
                        PHONE_HINT_REQUEST_CODE,
                        null, 0, 0, 0
                    )
                } catch (e: Exception) {
                    pendingResult?.error("LAUNCH_ERROR", "Failed to launch phone hint: ${e.message}", null)
                    pendingResult = null
                }
            }
            .addOnFailureListener { e ->
                pendingResult?.error("HINT_ERROR", "Phone number hint not available: ${e.message}", null)
                pendingResult = null
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == PHONE_HINT_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                try {
                    val phoneNumber = Identity.getSignInClient(this)
                        .getPhoneNumberFromIntent(data)
                    pendingResult?.success(phoneNumber)
                } catch (e: Exception) {
                    pendingResult?.error("PARSE_ERROR", "Failed to get phone number: ${e.message}", null)
                }
            } else {
                pendingResult?.error("CANCELLED", "User cancelled phone number selection", null)
            }
            pendingResult = null
        }
    }
}
