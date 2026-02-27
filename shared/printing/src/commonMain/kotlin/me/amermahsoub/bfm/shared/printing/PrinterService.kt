package me.amermahsoub.bfm.shared.printing

interface PrinterService {
    suspend fun print(payload: PrintPayload): PrintResult
}

data class PrintPayload(
    val target: PrinterTarget,
    val bytes: ByteArray,
    val timeoutMs: Int = 5_000,
)

sealed class PrinterTarget {
    data class Network(val host: String, val port: Int = 9_100) : PrinterTarget()
}

sealed class PrintResult {
    data object Success : PrintResult()
    data class Failure(val message: String, val cause: Throwable? = null) : PrintResult()
}
