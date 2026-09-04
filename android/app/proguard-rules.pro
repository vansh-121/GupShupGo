# ─────────────────────────────────────────────
# Global R8 options
# ─────────────────────────────────────────────
# Move classes into the unnamed (default) package so DEX drops the package
# prefix from every class name. Recommended for apps; becomes R8's default in
# AGP 9.1 (opt out there with -dontrepackage). Play Console → App optimization
# reports this as "Repackage Classes".
-repackageclasses

# -allowaccessmodification is NOT repeated here: it is already active via
# proguard-android-optimize.txt (see proguardFiles in app/build.gradle) and is
# implied by R8 full mode since AGP 8.2. Verified present in the merged config
# at build/app/outputs/mapping/release/configuration.txt.

# ─────────────────────────────────────────────
# WHY THIS FILE HAS SO FEW -keep RULES
# ─────────────────────────────────────────────
# Play Console → App optimization flagged release 52 (1.1.6) with
# "Obfuscation (25%)", tagged Bad behavior: under 25% in any category can
# affect store visibility and publishing.
#
# The cause was blanket `-keep class <sdk>.** { *; }` rules in this file. A
# blanket keep pins every class NAME in that package, so R8 cannot rename it —
# and it also blocks member-level shrinking, so the whole SDK surface ships
# even when unreachable. Measured from mapping.txt of the 1.1.6-era build
# (29,661 classes total, only 4,798 renamed = 16.2% obfuscated locally):
#
#     com.google.android.gms.**   14,728 classes pinned
#     com.google.firebase.**       2,453
#     androidx.media3.**           1,945
#     com.google.android.play.**     357
#     com.google.android.ump.**       19
#     com.google.android.exoplayer2.** 0  ← rule matched nothing at all
#
# None of those keeps were necessary. Every one of those SDKs ships its own
# consumer ProGuard rules inside its AAR, which R8 merges automatically — 60+
# such files are listed in mapping/release/configuration.txt. Google authors
# them precisely for the reflective/name-sensitive parts, e.g.
# play-services-basement's proguard.txt already supplies:
#
#     -keepnames class * implements ...common.internal.ReflectedParcelable
#     -keepclassmembers class * implements android.os.Parcelable { ... CREATOR; }
#     -keepnames @com.google.android.gms.common.annotation.KeepName class *
#     -keep @com.google.android.gms.common.util.DynamiteApi public class * {...}
#     -keep @androidx.annotation.Keep class *   (+ @Keep fields/methods)
#
# Rule of thumb for this file: do NOT add a keep for a third-party SDK. Assume
# its AAR carries correct rules, and only add one here if a release build
# actually misbehaves — narrowly, with a comment naming the symptom.
#
# The -dontwarn rules below are all retained. -dontwarn has no effect on
# obfuscation (it only suppresses warnings), and AGP 8 escalates missing
# classes to build errors, so dropping them would break the build instead.

# ─────────────────────────────────────────────
# THE REMAINING CEILING: ~30%, AND WHY IT IS NOT OURS TO FIX
# ─────────────────────────────────────────────
# After the cleanup above: 25,250 classes, 7,557 renamed = 29.9% (was 16.2%).
# 4,411 classes disappeared entirely once the shrinker was unblocked.
#
# What still cannot be renamed is pinned by dependencies, not by this file. The
# single biggest offender was confirmed with -whyareyoukeeping, not guessed:
#
#     $ -whyareyoukeeping class com.google.android.gms.internal.ads.zzaaa
#     com.google.android.gms.internal.ads.zzaaa
#     |- is referenced in keep rule:
#     |  .../jetified-firebase-auth-23.2.1/proguard.txt:20:1
#
# firebase-auth's own consumer rule, verbatim from its line 20:
#
#     -keep class com.google.android.gms.internal.** { *; }
#
# Its own comment two lines above says it only needs the *Response classes in
# `com.google.android.gms.internal.firebase-auth-api*` — but the glob it ships
# is the whole of gms.internal, so it drags in internal.ads (6,639 classes),
# internal.measurement, internal.play_billing and everything else that happens
# to live under that package. That is 12,058 of the ~17,700 classes still
# unobfuscated: on its own, roughly 48 points of the missing percentage.
#
# There is no -dontkeep in R8 — keep rules from AARs are merged additively and
# cannot be overridden from here. A version bump is not the lever either: the
# identical rule sits at the identical line 20 of firebase-auth 22.3.1, so it
# is longstanding upstream boilerplate rather than a regression, and bumping
# the BoM (33.14.0 today) has no expected gain to weigh against touching a live
# auth path. The only other route is rewriting the AAR's proguard.txt through a
# Gradle artifact transform — fragile, and not worth it here. So do NOT spend
# time trying to beat this number from this file; 29.9% clears Play's 25%.
#
# The rest, for the record: io.flutter 1,282 (deliberate, see below),
# io.agora ~865 + kotlin (Agora's own rules), Jackson 842 (callkit's rule).

# ─────────────────────────────────────────────
# Flutter engine — the one blanket keep that STAYS
# ─────────────────────────────────────────────
# Unlike every SDK above, the Flutter embedding AAR ships NO proguard.txt.
# flutter_tools only injects -dontwarn plus one conditional keep that
# explicitly *allows* obfuscation of FlutterPlugin implementations.
#
# libflutter.so calls back into Java by hardcoded JNI name (FindClass /
# GetMethodID on io.flutter.embedding.engine.FlutterJNI, io.flutter.view.*,
# io.flutter.plugin.common.*). AGP's default rule only protects classes that
# *declare* native methods:
#     -keepclasseswithmembernames class * { native <methods>; }
# That covers Java→native, not native→Java, so renaming these silently breaks
# release builds only. io.flutter.** is 1,282 of 29,661 classes (4%) — not
# worth the launch-crash risk when the SDK keeps above free ~19,500.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ─────────────────────────────────────────────
# Android core components
# ─────────────────────────────────────────────
# The four `-keep public class * extends android.app.{Activity,Application,
# Service}` / BroadcastReceiver / ContentProvider rules were removed. AGP
# already generates keep rules for every component in the MERGED manifest —
# 98 of them, in
#   build/app/intermediates/aapt_proguard_file/release/.../aapt_rules.txt
# including MainActivity, FirebaseMessagingService, FlutterFirebaseMessaging-
# Service and gms.ads.AdActivity. The blanket versions added nothing except
# pinning the name of every Activity/Service inside every bundled SDK.

# Preserve annotations, signatures and source info.
# SourceFile/LineNumberTable are what let Crashlytics deobfuscate stacks
# (AGP's defaults add -renamesourcefileattribute SourceFile). Signature is
# required for any generic-type reflection (Firestore, Gson, Jackson).
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# ─────────────────────────────────────────────
# Firebase / Google Play services — warnings only, no keeps
# ─────────────────────────────────────────────
# Keeps removed (see header). These -dontwarn entries stay: with the classes
# now visible to R8's shrinker, unreachable optional references inside the
# SDKs would otherwise fail the build.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.ump.**

# The deprecated SafetyNet App Check provider is excluded in build.gradle
# (firebase-appcheck-safetynet / play-services-safetynet). The app_check plugin
# still references SafetyNetAppCheckProviderFactory in an unreachable branch
# (we only use Play Integrity), so tell R8 not to fail on the missing class.
# Covered by the broad -dontwarn com.google.firebase.** above too; kept explicit
# to document the exclusion.
-dontwarn com.google.firebase.appcheck.safetynet.**

# ─────────────────────────────────────────────
# Agora RTC Engine
# ─────────────────────────────────────────────
# No keeps here. agora_rtc_engine's own consumer proguard.txt already contains
#     -keep class io.agora.**{*;}
#     -keep class kotlin.** { *; }
#     -keep class org.jetbrains.** { *; }
# so the copies previously in this file (io.agora.**, io.agora.rtc2.**,
# io.agora.rtc.**, kotlin.**) were exact duplicates — removing them changes
# nothing about what ships. Agora is why ~865 io.agora.* and ~300 kotlin.*
# classes stay unobfuscated; that is upstream's choice, not fixable here.
-dontwarn io.agora.**
-dontwarn kotlin.**

# Kotlin intrinsics that R8 needs structurally regardless of the above.
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata { *; }

# ─────────────────────────────────────────────
# Video playback (androidx.media3)
# ─────────────────────────────────────────────
# Keep removed. media3-exoplayer/-extractor/-datasource/-common each ship a
# proguard.txt with exact rules for their reflectively-instantiated renderers
# (LibvpxVideoRenderer, LibflacAudioRenderer, MidiRenderer, the offline
# downloaders, …). Dropping the blanket keep also lets R8 strip the container
# formats and decoders video_player never touches.
#
# com.google.android.exoplayer2.** rules are gone entirely: that package is
# not in the build (0 classes in mapping.txt) — video_player is on media3.
-dontwarn androidx.media3.**

# ─────────────────────────────────────────────
# Flutter plugins — no keeps needed
# ─────────────────────────────────────────────
# flutter_callkit_incoming and mobile_scanner ship their own consumer rules
# (callkit pins com.hiennv.** and com.fasterxml.**, which is why ~842 Jackson
# classes stay unobfuscated — again upstream's choice). permission_handler,
# image_picker, shared_preferences and audioplayers are reached by direct
# constructor calls from GeneratedPluginRegistrant and are already covered by
# the io.flutter.plugins.** keep above.
-dontwarn com.hiennv.flutter_callkit_incoming.**
-dontwarn com.baseflow.permissionhandler.**
-dontwarn xyz.luan.audioplayers.**

# ─────────────────────────────────────────────
# OkHttp / Okio (transitive via Firebase & Agora)
# ─────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**

# ─────────────────────────────────────────────
# JSON / Gson (used by flutter_local_notifications to persist
# scheduled notifications — reflective, so these keeps are real)
# ─────────────────────────────────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ─────────────────────────────────────────────
# Jackson Databind (transitive via flutter_callkit_incoming)
# java.beans.* and org.w3c.dom.bootstrap.* are Java SE classes not present on
# Android — safe to ignore because those code paths are never reached there.
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
