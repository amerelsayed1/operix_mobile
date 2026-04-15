package me.amermahsoub.bfm.shared.data.common

import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.plugins.ResponseException
import io.ktor.client.plugins.ServerResponseException
import io.ktor.client.statement.bodyAsText
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.domain.common.AppError

/**
 * Maps low-level Ktor exceptions into the shared [AppError] taxonomy.
 * Used by repositories to expose typed failures to the UI layer.
 */
suspend fun Throwable.toAppError(json: Json = Json { ignoreUnknownKeys = true }): AppError {
    return when (this) {
        is ClientRequestException -> mapClientError(json)
        is ServerResponseException -> AppError.Server(message = "Server error (${response.status.value})")
        is ResponseException -> AppError.Unknown(message = "HTTP ${response.status.value}")
        else -> {
            val msg = message.orEmpty().lowercase()
            if (msg.contains("unable to reach") ||
                msg.contains("network") ||
                msg.contains("connect") ||
                msg.contains("host")
            ) {
                AppError.Network(cause = this)
            } else {
                AppError.Unknown(message = message ?: "Unknown error", cause = this)
            }
        }
    }
}

private suspend fun ClientRequestException.mapClientError(json: Json): AppError {
    val status = response.status.value
    val body = runCatching { response.bodyAsText() }.getOrNull().orEmpty()
    val parsed = runCatching { json.decodeFromString(ValidationErrorBody.serializer(), body) }.getOrNull()

    return when (status) {
        400 -> AppError.Validation(message = parsed?.message ?: "Bad request", fieldErrors = parsed?.errors.orEmpty())
        401 -> AppError.Unauthorized(message = parsed?.message ?: "Session expired")
        402 -> AppError.SubscriptionInactive(message = parsed?.message ?: "Subscription inactive")
        403 -> AppError.Forbidden(message = parsed?.message ?: "You don't have permission")
        404 -> AppError.NotFound(message = parsed?.message ?: "Not found")
        422 -> AppError.Validation(message = parsed?.message ?: "Invalid data", fieldErrors = parsed?.errors.orEmpty())
        429 -> {
            val retryAfter = response.headers["Retry-After"]?.toIntOrNull() ?: 5
            AppError.RateLimited(retryAfterSeconds = retryAfter, message = parsed?.message ?: "Too many requests")
        }
        else -> AppError.Unknown(message = parsed?.message ?: "HTTP $status")
    }
}
