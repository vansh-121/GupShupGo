package com.gupshupgo.app

import org.junit.Assert.*
import org.junit.Test

class CallRegistrationStateTest {
    @Test fun `same account device migration preserves calls but sign out invalidates them`() {
        val old = registered()
        assertFalse(old.shouldClearCallsFor("alice"))
        assertFalse(old.bind("alice", "migrated-phone").shouldClearCallsFor("alice"))
        assertTrue(old.shouldClearCallsFor("bob"))
        assertTrue(old.clear().shouldClearCallsFor("alice"))
    }
    private fun pending() = CallRegistrationState().bind("alice", "phone").observeToken("token-1")
    private fun registered(): CallRegistrationState {
        val state = pending()
        return state.confirm(state, "alice")!!
    }

    @Test fun `having a cached token does not imply successful server registration`() {
        assertFalse(pending().isRegistered("alice"))
        // An upgraded installation has no acknowledgement, even if it has an old token.
        assertFalse(CallRegistrationState("alice", "phone", "legacy-token").isRegistered("alice"))
    }

    @Test fun `server acknowledgement confirms only the signed in binding`() {
        assertTrue(registered().isRegistered("alice"))
        assertFalse(registered().isRegistered(null))
        assertFalse(registered().isRegistered("bob"))
        val state = pending()
        assertNull(state.confirm(state, "bob"))
    }

    @Test fun `a rotated token stays pending until its own write succeeds`() {
        val oldAttempt = pending()
        val rotated = registered().observeToken("token-2")
        assertFalse(rotated.isRegistered("alice"))
        assertNull(rotated.confirm(oldAttempt, "alice"))
        assertTrue(rotated.confirm(rotated, "alice")!!.isRegistered("alice"))
    }

    @Test fun `a late token fetch cannot overwrite a newer token callback`() {
        val beforeFetch = registered()
        val afterCallback = beforeFetch.observeToken("token-2")
        assertFalse(afterCallback.sameAttempt(beforeFetch))
    }

    @Test fun `changing account or device invalidates an earlier acknowledgement`() {
        val old = registered()
        for (state in listOf(old.bind("bob", "phone"), old.bind("alice", "new-phone"))) {
            assertFalse(state.isRegistered(state.userId))
            assertNull(state.confirm(old, state.userId))
        }
    }

    @Test fun `signing out and back into the same account rejects an old in flight write`() {
        val oldAttempt = pending()
        val cleared = registered().clear()
        assertFalse(cleared.isRegistered("alice"))
        val rebound = cleared.bind("alice", "phone").observeToken("token-1")
        assertFalse(rebound.isRegistered("alice"))
        assertNull(rebound.confirm(oldAttempt, "alice"))
        assertTrue(rebound.confirm(rebound, "alice")!!.isRegistered("alice"))
    }

    @Test fun `routine setup and duplicate token callbacks preserve a valid acknowledgement`() {
        val state = registered().bind("alice", "phone").observeToken("token-1")
        assertTrue(state.isRegistered("alice"))
        // Persisted fields can be restored without losing the confirmed status.
        assertTrue(state.copy().isRegistered("alice"))
    }
}
