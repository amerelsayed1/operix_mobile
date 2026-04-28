package me.amermahsoub.bfm.shared.data.api

sealed class ApiException(message: String) : Exception(message) {

    abstract val displayMessage: String

    /** 422 — Laravel validation errors. fieldErrors maps field name → list of messages. */
    class Validation(
        override val message: String,
        val fieldErrors: Map<String, List<String>> = emptyMap(),
    ) : ApiException(message) {
        override val displayMessage: String get() =
            if (fieldErrors.isEmpty()) message
            else fieldErrors.values.flatten().joinToString("\n")
    }

    /** 401 / 403 */
    class Auth(override val message: String) : ApiException(message) {
        override val displayMessage: String get() = message
    }

    /** 404 */
    class NotFound(override val message: String) : ApiException(message) {
        override val displayMessage: String get() = message
    }

    /** 5xx or any unexpected HTTP status */
    class Server(override val message: String, val code: Int) : ApiException(message) {
        override val displayMessage: String get() = "Server error ($code). Please try again."
    }

    /** No connectivity / timeout */
    class Network(override val message: String) : ApiException(message) {
        override val displayMessage: String get() = "No internet connection. Please check your network."
    }
}
