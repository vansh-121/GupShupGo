package com.gupshupgo.app

import org.junit.Assert.*
import org.junit.Test

class CallPolicyTest {
    @Test fun `legacy pushes expire from FCM send time not process startup`() {
        assertEquals(61000L, CallPolicy.expiresAt(emptyMap(), 1000))
        assertFalse(CallPolicy.canRing(62000, 61000, false))
    }
    @Test fun `replayed calls and cancel-before-invite tombstones cannot ring`() {
        assertFalse(CallPolicy.canRing(1000, 61000, true))
        assertTrue(CallPolicy.canRing(1000, 61000, false))
    }
    @Test fun `server expiry bounds delayed delivery and rejects exact deadline`() {
        val expiry = CallPolicy.expiresAt(mapOf("expiresAt" to "1500"), 1000)!!
        assertTrue(CallPolicy.canRing(1499, expiry, false))
        assertFalse(CallPolicy.canRing(1500, expiry, false))
    }
    @Test fun `malformed timestamps cannot create unlimited ringing`() {
        assertNull(CallPolicy.expiresAt(emptyMap(), 0))
        assertEquals(61000L, CallPolicy.expiresAt(mapOf("expiresAt" to "9999999999999"), 1000))
        assertFalse(CallPolicy.canRing(1000, 999999999, false))
    }
    @Test fun `ids cannot inject paths into intents or Firestore`() {
        assertTrue(CallPolicy.validId("e0fb66da-8201-4cb3-82d5-613b59b0a492"))
        for (id in listOf("", "a/b", "a?x", "x".repeat(129))) assertFalse(CallPolicy.validId(id))
    }
}
