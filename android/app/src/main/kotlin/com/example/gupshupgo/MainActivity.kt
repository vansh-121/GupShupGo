package com.gupshupgo.app

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.MediaRecorder
import android.os.Build
import android.util.Rational
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.gupshupgo.app/phone_verification"
    private val AUDIO_CHANNEL = "com.gupshupgo.app/audio_recorder"
    private val PIP_CHANNEL = "com.gupshupgo.app/pip"
    private val PHONE_HINT_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    private var mediaRecorder: MediaRecorder? = null

    // ── Picture-in-Picture state ────────────────────────────────────────
    // Retained so onUserLeaveHint (the manual auto-enter fallback for
    // Android 8.0–11, which lack setAutoEnterEnabled) knows whether a video
    // call is currently active and what aspect ratio to use.
    private var pipChannel: MethodChannel? = null
    private var pipCallActive = false
    private var pipAspectNumerator = 9
    private var pipAspectDenominator = 16

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

        // ── Picture-in-Picture method channel ──────────────────────────
        val pip = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipChannel = pip
        pip.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> {
                    result.success(isPipSupported())
                }
                "enableAutoEnterPip" -> {
                    // A video call connected: remember it's active (for the
                    // onUserLeaveHint fallback) and, on API 31+, arm the system
                    // to auto-enter PiP when the user leaves the activity.
                    val num = call.argument<Int>("aspectNumerator")
                    val den = call.argument<Int>("aspectDenominator")
                    enableAutoEnterPip(num, den)
                    result.success(isPipSupported())
                }
                "disablePip" -> {
                    // The video call ended: clear active state and, on API 31+,
                    // disarm auto-enter so PiP won't fire from other screens.
                    disablePip()
                    result.success(null)
                }
                "enterPipNow" -> {
                    // Explicit request (e.g. a "minimize" button) to enter PiP
                    // right away. Returns false on unsupported OS versions.
                    result.success(enterPipNow())
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
        // Reject an overlapping request instead of overwriting a pending one.
        // Overwriting would leave the first Dart Future hanging forever (its
        // onActivityResult would resolve the wrong Result). The hint is a
        // best-effort convenience, so failing the new call fast is fine.
        if (pendingResult != null) {
            result.error(
                "IN_PROGRESS",
                "A phone number hint request is already in progress.",
                null
            )
            return
        }
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

    // ── Picture-in-Picture helpers ─────────────────────────────────────

    // PiP needs API 26+ AND hardware that declares the feature (some low-end
    // devices don't). minSdk is 24, so the two lowest supported OS versions
    // lack PiP — always gate at runtime.
    private fun isPipSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    // Build PiP params for the current video call. On API 31+ we also carry the
    // auto-enter flag so leaving the activity drops straight into PiP.
    private fun buildPipParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(pipAspectNumerator, pipAspectDenominator))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(pipCallActive)
        }
        return builder.build()
    }

    private fun enableAutoEnterPip(aspectNumerator: Int?, aspectDenominator: Int?) {
        if (!isPipSupported()) return
        pipCallActive = true
        // Guard against a zero/negative denominator that would crash Rational.
        if (aspectNumerator != null && aspectNumerator > 0 &&
            aspectDenominator != null && aspectDenominator > 0) {
            pipAspectNumerator = aspectNumerator
            pipAspectDenominator = aspectDenominator
        }
        // API 31+ can auto-enter with no onUserLeaveHint plumbing.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            buildPipParams()?.let {
                try {
                    setPictureInPictureParams(it)
                } catch (_: Exception) {
                    // Some OEMs throw if called in a bad state — safe to ignore.
                }
            }
        }
    }

    private fun disablePip() {
        pipCallActive = false
        // Disarm auto-enter so leaving a non-call screen won't shrink into PiP.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                setPictureInPictureParams(
                    PictureInPictureParams.Builder()
                        .setAutoEnterEnabled(false)
                        .build()
                )
            } catch (_: Exception) {
                // Ignore — nothing to disarm if we were never armed.
            }
        }
    }

    // Explicit "enter PiP now" request. The inline SDK_INT guard (not just the
    // one inside isPipSupported()) is what lets lintVital see this API-26 call
    // is safe, so release builds don't fail on NewApi.
    private fun enterPipNow(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!isPipSupported() || !pipCallActive) return false
        val params = buildPipParams() ?: return false
        return try {
            enterPictureInPictureMode(params)
        } catch (_: Exception) {
            false
        }
    }

    // ── Picture-in-Picture lifecycle ───────────────────────────────────

    // Manual auto-enter fallback for Android 8.0–11 (API 26–30), which lack
    // setAutoEnterEnabled. When the user presses Home / recents during an
    // active video call, drop into PiP instead of backgrounding the call.
    // Two sequential SDK_INT early-returns bound this to 26..30 AND let
    // lintVital prove the enterPictureInPictureMode call is API-safe.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return // 31+ auto-enters
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return  // <26 has no PiP
        if (!pipCallActive || !isPipSupported()) return
        val params = buildPipParams() ?: return
        try {
            enterPictureInPictureMode(params)
        } catch (_: Exception) {
            // A failed transition just backgrounds the app normally — fine.
        }
    }

    // Tell Dart when PiP mode toggles so the call UI can hide its controls
    // (in PiP only the remote video should show).
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod(
            "onPipModeChanged",
            mapOf("isInPipMode" to isInPictureInPictureMode)
        )
    }
}
