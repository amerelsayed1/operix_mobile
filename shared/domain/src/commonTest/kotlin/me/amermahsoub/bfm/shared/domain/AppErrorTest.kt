package me.amermahsoub.bfm.shared.domain

import me.amermahsoub.bfm.shared.domain.common.AppError
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AppErrorTest {

    @Test
    fun network_defaultMessage() {
        val error = AppError.Network()
        assertEquals("Check your connection", error.message)
    }

    @Test
    fun network_customMessage() {
        val error = AppError.Network(message = "No Wi-Fi")
        assertEquals("No Wi-Fi", error.message)
    }

    @Test
    fun network_causePreservation() {
        val cause = RuntimeException("timeout")
        val error = AppError.Network(cause = cause)
        assertEquals(cause, error.cause)
    }

    @Test
    fun network_causeNullByDefault() {
        val error = AppError.Network()
        assertNull(error.cause)
    }

    @Test
    fun unauthorized_defaultMessage() {
        val error = AppError.Unauthorized()
        assertEquals("Session expired", error.message)
    }

    @Test
    fun unauthorized_customMessage() {
        val error = AppError.Unauthorized(message = "Token invalid")
        assertEquals("Token invalid", error.message)
    }

    @Test
    fun subscriptionInactive_defaultMessage() {
        val error = AppError.SubscriptionInactive()
        assertEquals("Subscription inactive", error.message)
    }

    @Test
    fun subscriptionInactive_customMessage() {
        val error = AppError.SubscriptionInactive(message = "Plan expired")
        assertEquals("Plan expired", error.message)
    }

    @Test
    fun forbidden_defaultMessage() {
        val error = AppError.Forbidden()
        assertEquals("You don't have permission", error.message)
    }

    @Test
    fun forbidden_customMessage() {
        val error = AppError.Forbidden(message = "Access denied")
        assertEquals("Access denied", error.message)
    }

    @Test
    fun notFound_defaultMessage() {
        val error = AppError.NotFound()
        assertEquals("Not found", error.message)
    }

    @Test
    fun notFound_customMessage() {
        val error = AppError.NotFound(message = "Invoice not found")
        assertEquals("Invoice not found", error.message)
    }

    @Test
    fun validation_messageRequired() {
        val error = AppError.Validation(message = "Invalid input")
        assertEquals("Invalid input", error.message)
    }

    @Test
    fun validation_fieldErrorsDefaultEmpty() {
        val error = AppError.Validation(message = "Invalid")
        assertTrue(error.fieldErrors.isEmpty())
    }

    @Test
    fun validation_fieldErrorsPreserved() {
        val fieldErrors = mapOf(
            "email" to listOf("Email is required", "Email format invalid"),
            "name" to listOf("Name is required")
        )
        val error = AppError.Validation(message = "Validation failed", fieldErrors = fieldErrors)
        assertEquals(2, error.fieldErrors.size)
        assertEquals(listOf("Email is required", "Email format invalid"), error.fieldErrors["email"])
        assertEquals(listOf("Name is required"), error.fieldErrors["name"])
    }

    @Test
    fun server_defaultMessage() {
        val error = AppError.Server()
        assertEquals("Server error", error.message)
    }

    @Test
    fun server_customMessage() {
        val error = AppError.Server(message = "Internal server error")
        assertEquals("Internal server error", error.message)
    }

    @Test
    fun rateLimited_defaultMessage() {
        val error = AppError.RateLimited()
        assertEquals("Too many requests", error.message)
    }

    @Test
    fun rateLimited_customMessage() {
        val error = AppError.RateLimited(message = "Slow down")
        assertEquals("Slow down", error.message)
    }

    @Test
    fun rateLimited_retryAfterSecondsDefault() {
        val error = AppError.RateLimited()
        assertEquals(0, error.retryAfterSeconds)
    }

    @Test
    fun rateLimited_retryAfterSecondsCustom() {
        val error = AppError.RateLimited(retryAfterSeconds = 30)
        assertEquals(30, error.retryAfterSeconds)
    }

    @Test
    fun unknown_defaultMessage() {
        val error = AppError.Unknown()
        assertEquals("Something went wrong", error.message)
    }

    @Test
    fun unknown_customMessage() {
        val error = AppError.Unknown(message = "Unexpected failure")
        assertEquals("Unexpected failure", error.message)
    }

    @Test
    fun unknown_causePreservation() {
        val cause = IllegalStateException("bad state")
        val error = AppError.Unknown(cause = cause)
        assertEquals(cause, error.cause)
    }

    @Test
    fun typeChecking_network() {
        val error: AppError = AppError.Network()
        assertIs<AppError.Network>(error)
        assertIs<AppError>(error)
    }

    @Test
    fun typeChecking_unauthorized() {
        val error: AppError = AppError.Unauthorized()
        assertIs<AppError.Unauthorized>(error)
    }

    @Test
    fun typeChecking_validation() {
        val error: AppError = AppError.Validation(message = "bad")
        assertIs<AppError.Validation>(error)
    }

    @Test
    fun typeChecking_rateLimited() {
        val error: AppError = AppError.RateLimited()
        assertIs<AppError.RateLimited>(error)
    }
}
