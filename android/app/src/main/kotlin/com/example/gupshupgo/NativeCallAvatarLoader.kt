package com.gupshupgo.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.Future

/** Optional decoration: network or decode failures must never delay a ringing call. */
internal object NativeCallAvatarLoader {
    private const val MAX_BYTES = 2 * 1024 * 1024
    private val executor = Executors.newSingleThreadExecutor { task ->
        Thread(task, "native-call-avatar").apply { isDaemon = true }
    }

    fun load(url: String, size: Int, onLoaded: (Bitmap?) -> Unit): Future<*>? {
        if (url.isBlank()) return null
        return executor.submit {
            val bitmap = runCatching { download(url, size) }.getOrNull()
            if (!Thread.currentThread().isInterrupted) onLoaded(bitmap)
        }
    }

    private fun download(value: String, size: Int): Bitmap? {
        val url = URL(value)
        if (url.protocol != "https") return null
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.connectTimeout = 3000
            connection.readTimeout = 3000
            if (connection.responseCode != HttpURLConnection.HTTP_OK || connection.contentLength > MAX_BYTES) return null
            val bytes = connection.inputStream.use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(8192)
                while (true) {
                    if (Thread.currentThread().isInterrupted) return null
                    val count = input.read(buffer)
                    if (count == -1) break
                    if (output.size() + count > MAX_BYTES) return null
                    output.write(buffer, 0, count)
                }
                output.toByteArray()
            }
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            // Cap both dimensions during decode, including unusually tall/wide images.
            var sample = 1
            val limit = size.coerceAtLeast(1) * 2
            while (bounds.outWidth / sample > limit || bounds.outHeight / sample > limit) sample *= 2
            return BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
                BitmapFactory.Options().apply { inSampleSize = sample })
        } finally {
            connection.disconnect()
        }
    }
}
