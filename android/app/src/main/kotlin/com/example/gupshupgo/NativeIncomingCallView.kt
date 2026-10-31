package com.gupshupgo.app

import android.animation.ValueAnimator
import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.PaintDrawable
import android.graphics.drawable.RippleDrawable
import android.graphics.drawable.ShapeDrawable
import android.graphics.drawable.shapes.RectShape
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import java.util.Locale
import java.util.concurrent.Future
import kotlin.math.roundToInt

/** Mirrors the Flutter call palette, without needing an engine on a cold start. */
class NativeIncomingCallView(
    context: Context,
    private val callerName: String,
    private val callerPhotoUrl: String,
    private val isAudioOnly: Boolean,
    private val onAccept: () -> Unit,
    private val onDecline: () -> Unit,
) : FrameLayout(context) {
    private val compact = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    private val avatarSize = if (compact) 128 else 144
    private val pulseRing = View(context)
    private val photo = ImageView(context)
    private val initials = label(callerInitials(), 44f, Color.WHITE, "sans-serif-light")
    private val buttons = mutableListOf<ImageButton>()
    private var pulse: ValueAnimator? = null
    private var photoRequest: Future<*>? = null
    private var actionTaken = false

    init {
        background = PaintDrawable().apply {
            shape = RectShape()
            shaderFactory = object : ShapeDrawable.ShaderFactory() {
                override fun resize(width: Int, height: Int): Shader = LinearGradient(
                    0f, 0f, 0f, height.coerceAtLeast(1).toFloat(),
                    intArrayOf(color(R.color.native_call_teal), color(R.color.native_call_mid),
                        color(R.color.native_call_dark), color(R.color.native_call_dark)),
                    floatArrayOf(0f, 0.3f, 0.6f, 1f), Shader.TileMode.CLAMP,
                )
            }
        }
        ViewCompat.setOnApplyWindowInsetsListener(this) { view, insets ->
            val safe = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(safe.left, safe.top, safe.right, safe.bottom)
            insets
        }

        val body = column().apply { setPadding(dp(24), dp(24), dp(24), dp(if (compact) 24 else 40)) }
        addView(ScrollView(context).apply {
            isFillViewport = true
            isVerticalScrollBarEnabled = false
            overScrollMode = OVER_SCROLL_NEVER
            addView(body, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        }, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        body.addView(label(context.getString(R.string.native_call_app_name), 14f, 0xD9FFFFFF.toInt(), "sans-serif-medium").apply {
            letterSpacing = 0.04f
            importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        })

        val identity = column().apply {
            addView(label(callerName, 32f, Color.WHITE, "sans-serif-medium").apply {
                maxLines = 2
                ellipsize = TextUtils.TruncateAt.END
                ViewCompat.setAccessibilityHeading(this, true)
            }, rowParams())
            addView(LinearLayout(context).apply {
                gravity = Gravity.CENTER
                orientation = LinearLayout.HORIZONTAL
                val callIcon = if (isAudioOnly) R.drawable.ic_call_notification else R.drawable.ic_native_call_video
                addView(ImageView(context).apply {
                    setImageResource(callIcon)
                    imageTintList = ColorStateList.valueOf(0xCCFFFFFF.toInt())
                    importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
                }, LinearLayout.LayoutParams(dp(17), dp(17)).apply { marginEnd = dp(8) })
                addView(label(context.getString(if (isAudioOnly) R.string.native_call_incoming_voice
                    else R.string.native_call_incoming_video), 16f, 0xCCFFFFFF.toInt()))
            }, rowParams(top = 10))
        }

        val actions = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(action(R.drawable.ic_native_call_decline, R.color.native_call_decline,
                R.string.native_call_decline, R.string.native_call_decline_description, onDecline),
                LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
            addView(action(if (isAudioOnly) R.drawable.ic_call_notification else R.drawable.ic_native_call_video,
                R.color.native_call_teal, R.string.native_call_accept,
                if (isAudioOnly) R.string.native_call_accept_voice else R.string.native_call_accept_video, onAccept),
                LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        }

        if (compact) {
            // Keep both actions visible in landscape instead of putting them below the fold.
            body.addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                addView(avatar(), LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
                addView(column().apply {
                    addView(identity, rowParams())
                    addView(actions, rowParams(top = 28))
                }, LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1.4f))
            }, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f).apply { topMargin = dp(20) })
        } else {
            body.addView(View(context), LinearLayout.LayoutParams(0, dp(36), 0.65f))
            body.addView(avatar())
            body.addView(identity, rowParams(top = 28))
            body.addView(View(context), LinearLayout.LayoutParams(0, dp(48), 1.35f))
            body.addView(actions, LinearLayout.LayoutParams(dp(minOf(320, resources.configuration.screenWidthDp - 48)),
                LayoutParams.WRAP_CONTENT))
        }
    }

    private fun avatar(): FrameLayout = FrameLayout(context).apply {
        layoutParams = LinearLayout.LayoutParams(dp(avatarSize + 40), dp(avatarSize + 40))
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        addView(pulseRing.apply { background = circle(0x0DFFFFFF, 0x33FFFFFF) },
            LayoutParams(dp(avatarSize + 32), dp(avatarSize + 32), Gravity.CENTER))
        addView(View(context).apply { background = circle(0x12FFFFFF, 0x40FFFFFF) },
            LayoutParams(dp(avatarSize + 12), dp(avatarSize + 12), Gravity.CENTER))
        addView(FrameLayout(context).apply {
            background = circle(0xFF327969.toInt())
            clipToOutline = true
            addView(initials, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
            addView(photo.apply { scaleType = ImageView.ScaleType.CENTER_CROP },
                LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        }, LayoutParams(dp(avatarSize), dp(avatarSize), Gravity.CENTER))
    }

    private fun action(icon: Int, tint: Int, title: Int, description: Int, callback: () -> Unit) = column().apply {
        addView(ImageButton(context).apply {
            background = RippleDrawable(ColorStateList.valueOf(0x33FFFFFF), circle(color(tint), 0x20FFFFFF), circle(Color.WHITE))
            setImageResource(icon)
            imageTintList = ColorStateList.valueOf(Color.WHITE)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setPadding(dp(21), dp(21), dp(21), dp(21))
            contentDescription = context.getString(description)
            elevation = dp(4).toFloat()
            setOnClickListener {
                if (!actionTaken) {
                    actionTaken = true
                    buttons.forEach { it.isEnabled = false }
                    performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                    callback()
                }
            }
            buttons.add(this)
        }, LinearLayout.LayoutParams(dp(76), dp(76)))
        addView(label(context.getString(title), 14f, 0xE6FFFFFF.toInt()).apply {
            importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        }, rowParams(top = 12))
    }

    private fun label(value: String, size: Float, tint: Int, font: String = "sans-serif") = TextView(context).apply {
        text = value
        textSize = size
        setTextColor(tint)
        typeface = Typeface.create(font, Typeface.NORMAL)
        gravity = Gravity.CENTER
        includeFontPadding = false
    }

    private fun column() = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }

    private fun rowParams(top: Int = 0) = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
        topMargin = dp(top)
    }

    private fun circle(tint: Int, stroke: Int = Color.TRANSPARENT) = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(tint)
        setStroke(dp(1), stroke)
    }

    private fun color(id: Int) = context.getColor(id)
    private fun dp(value: Int) = (value * resources.displayMetrics.density).roundToInt()

    private fun callerInitials(): String {
        val words = callerName.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
        val parts = if (words.size > 1) listOf(words.first(), words.last()) else words
        return parts.joinToString("") { it.substring(0, it.offsetByCodePoints(0, 1)) }.uppercase(Locale.getDefault())
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        ViewCompat.requestApplyInsets(this)
        updatePulse()
        photoRequest = NativeCallAvatarLoader.load(callerPhotoUrl, dp(avatarSize)) { bitmap ->
            post {
                if (isAttachedToWindow && bitmap != null) {
                    photo.setImageBitmap(bitmap)
                    initials.visibility = INVISIBLE
                }
            }
        }
    }

    override fun onWindowVisibilityChanged(visibility: Int) {
        super.onWindowVisibilityChanged(visibility)
        updatePulse()
    }

    private fun updatePulse() {
        pulse?.cancel()
        pulse = null
        val motionEnabled = if (Build.VERSION.SDK_INT >= 26) ValueAnimator.areAnimatorsEnabled()
            else Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) != 0f
        if (!isAttachedToWindow || windowVisibility != VISIBLE || !motionEnabled) return
        pulse = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 1800
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.REVERSE
            interpolator = AccelerateDecelerateInterpolator()
            addUpdateListener {
                val progress = it.animatedValue as Float
                pulseRing.scaleX = 1f + progress * 0.06f
                pulseRing.scaleY = pulseRing.scaleX
                pulseRing.alpha = 1f - progress * 0.45f
            }
            start()
        }
    }

    override fun onDetachedFromWindow() {
        pulse?.cancel()
        pulse = null
        photoRequest?.cancel(true)
        photoRequest = null
        super.onDetachedFromWindow()
    }
}
