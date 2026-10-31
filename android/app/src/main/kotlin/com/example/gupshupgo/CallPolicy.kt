package com.gupshupgo.app

/** Pure policy shared by receipt, presentation, and Accept. Times are UTC millis. */
object CallPolicy {
    const val RING_MS = 60_000L
    const val TOMBSTONE_MS = 24 * 60 * 60 * 1000L
    private val safeId = Regex("[A-Za-z0-9_-]{1,128}")
    fun validId(id: String) = safeId.matches(id)

    fun expiresAt(data: Map<String, String>, sentTime: Long): Long? {
        val explicit = data["expiresAt"]?.toLongOrNull()
        // Legacy senders get a bounded window based on FCM's send time.
        val sent = sentTime.takeIf { it > 0 } ?: return null
        return minOf(explicit ?: (sent + RING_MS), sent + RING_MS)
    }

    fun canRing(now: Long, expiresAt: Long, handled: Boolean): Boolean =
        !handled && expiresAt > now && expiresAt - now <= RING_MS

    // An answer push can beat the transaction response and older deployments
    // may omit the winning device. Once Accept was tapped, only the server
    // transaction may decide who won; do not erase its inbox on this hint.
    fun shouldDismissForStatus(status: String?, localState: String): Boolean =
        status != "ringing" && !(status == "answered" && localState in setOf("accepted", "connected"))
}
