package com.gupshupgo.app

/** A server acknowledgement is valid only for the current binding and token. */
data class CallRegistrationState(
    val userId: String? = null,
    val deviceId: String? = null,
    val token: String? = null,
    val registeredToken: String? = null,
    val generation: Long = 0,
) {
    fun isBound(authUserId: String?) = !userId.isNullOrEmpty() &&
        !deviceId.isNullOrEmpty() && userId == authUserId

    fun isRegistered(authUserId: String?) = isBound(authUserId) &&
        !token.isNullOrEmpty() && token == registeredToken

    fun bind(uid: String, device: String) =
        if (userId == uid && deviceId == device) this
        else copy(userId = uid, deviceId = device, registeredToken = null, generation = generation + 1)

    fun observeToken(value: String) =
        if (token == value) this
        else copy(token = value, registeredToken = null, generation = generation + 1)

    // Keep the generation across sign-out, including signing back into the same account.
    fun clear() = CallRegistrationState(generation = generation + 1)

    fun sameAttempt(attempt: CallRegistrationState) = generation == attempt.generation &&
        userId == attempt.userId && deviceId == attempt.deviceId && token == attempt.token

    fun confirm(attempt: CallRegistrationState, authUserId: String?): CallRegistrationState? =
        if (isBound(authUserId) && !token.isNullOrEmpty() && sameAttempt(attempt))
            copy(registeredToken = token)
        else null
}
