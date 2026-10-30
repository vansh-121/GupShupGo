package com.gupshupgo.app

import android.app.Application
import android.content.pm.ApplicationInfo
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.AppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory

/** Firestore calls from FCM/WorkManager need App Check before Flutter exists. */
class GupShupApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val provider = if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            // Debug provider is a debugImplementation and never bundled in release.
            runCatching {
                Class.forName("com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory")
                    .getMethod("getInstance").invoke(null) as AppCheckProviderFactory
            }.getOrElse { PlayIntegrityAppCheckProviderFactory.getInstance() }
        } else PlayIntegrityAppCheckProviderFactory.getInstance()
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(provider)
    }
}
