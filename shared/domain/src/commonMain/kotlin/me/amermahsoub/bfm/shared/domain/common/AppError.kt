package me.amermahsoub.bfm.shared.domain.common

/**
 * Normalized error taxonomy surfaced to the UI layer.
 */
sealed class AppError(open val message: String, open val cause: Throwable? = null) {
    data class Network(override val message: String = "Check your connection", override val cause: Throwable? = null) : AppError(message, cause)
    data class Unauthorized(override val message: String = "Session expired") : AppError(message)
    data class SubscriptionInactive(override val message: String = "Subscription inactive") : AppError(message)
    data class Forbidden(override val message: String = "You don't have permission") : AppError(message)
    data class NotFound(override val message: String = "Not found") : AppError(message)
    data class Validation(override val message: String, val fieldErrors: Map<String, List<String>> = emptyMap()) : AppError(message)
    data class Server(override val message: String = "Server error") : AppError(message)
    data class RateLimited(val retryAfterSeconds: Int = 0, override val message: String = "Too many requests") : AppError(message)
    data class Unknown(override val message: String = "Something went wrong", override val cause: Throwable? = null) : AppError(message, cause)
}
