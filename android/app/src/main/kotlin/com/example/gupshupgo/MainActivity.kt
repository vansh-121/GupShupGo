package com.gupshupgo.app

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import android.media.MediaRecorder
import android.os.Build
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.gupshupgo.app/phone_verification"
    private val AUDIO_CHANNEL = "com.gupshupgo.app/audio_recorder"
    private val PHONE_HINT_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    private var mediaRecorder: MediaRecorder? = null

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

        // ── Audio recorder method channel ──────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARG", "Missing 'path' argument", null)
                        return@setMethodCallHandler
                    }
                    startRecording(path, result)
                }
                "stopRecording" -> {
                    stopRecording(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // ── Audio recording helpers ────────────────────────────────────────

    private fun startRecording(path: String, result: MethodChannel.Result) {
        try {
            stopRecordingSilently() // stop any existing recording

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setAudioChannels(1)
                setOutputFile(path)
                prepare()
                start()
            }

            result.success(null)
        } catch (e: Exception) {
            result.error("RECORD_ERROR", "Failed to start recording: ${e.message}", null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        try {
            stopRecordingSilently()
            result.success(null)
        } catch (e: Exception) {
            result.error("RECORD_ERROR", "Failed to stop recording: ${e.message}", null)
        }
    }

    private fun stopRecordingSilently() {
        mediaRecorder?.let { recorder ->
            try {
                recorder.stop()
            } catch (_: Exception) {
                // Already stopped or in an invalid state — ignore
            }
            try {
                recorder.release()
            } catch (_: Exception) {
                // Already released or in an invalid state — ignore
            }
        }
        mediaRecorder = null
    }

    // ── Phone number hint ──────────────────────────────────────────────

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
