# ─────────────────────────────────────────────
# Flutter engine
# ─────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ─────────────────────────────────────────────
# Kotlin
# ─────────────────────────────────────────────
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata { *; }

# ─────────────────────────────────────────────
# Android core components
# ─────────────────────────────────────────────
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Preserve annotations, signatures and source info for crash reporting
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# ─────────────────────────────────────────────
# Firebase (core, auth, firestore, storage, messaging, app-check)
# ─────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Messaging — keep notification handling classes
-keep class com.google.firebase.messaging.** { *; }

# Firebase App Check (Play Integrity)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ─────────────────────────────────────────────
# Google Sign-In
# ─────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# ─────────────────────────────────────────────
# Agora RTC Engine (native JNI bridges must not be stripped)
# ─────────────────────────────────────────────
-keep class io.agora.** { *; }
-dontwarn io.agora.**
-keep class io.agora.rtc2.** { *; }
-keep class io.agora.rtc.** { *; }

# ─────────────────────────────────────────────
# Flutter CallKit Incoming
# ─────────────────────────────────────────────
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

# ─────────────────────────────────────────────
# Permission Handler
# ─────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ─────────────────────────────────────────────
# Image Picker
# ─────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ─────────────────────────────────────────────
# Video Player (ExoPlayer)
# ─────────────────────────────────────────────
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ─────────────────────────────────────────────
# Shared Preferences
# ─────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ─────────────────────────────────────────────
# Audio Players
# ─────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# ─────────────────────────────────────────────
# OkHttp / Retrofit (used transitively by Firebase & Agora)
# ─────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ─────────────────────────────────────────────
# JSON / Gson (transitive)
# ─────────────────────────────────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ─────────────────────────────────────────────
# Jackson Databind (transitive via Firebase)
# java.beans.* and org.w3c.dom.bootstrap.* are
# Java SE classes not present on Android — safe
# to ignore because the code paths using them are
# never reached on Android.
# ─────────────────────────────────────────────
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
-dontwarn com.fasterxml.jackson.**

# ─────────────────────────────────────────────
# Suppress noisy warnings from transitive deps
# ─────────────────────────────────────────────
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
