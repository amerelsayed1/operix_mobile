package me.amermahsoub.bfm.shared.printing

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.core.module.Module
import org.koin.dsl.module
import java.net.InetSocketAddress
import java.net.Socket

class AndroidNetworkPrinterService : PrinterService {
    override suspend fun print(payload: PrintPayload): PrintResult = withContext(Dispatchers.IO) {
        when (val target = payload.target) {
            is PrinterTarget.Network -> sendOverSocket(target.host, target.port, payload.bytes, payload.timeoutMs)
        }
    }

    private fun sendOverSocket(host: String, port: Int, bytes: ByteArray, timeoutMs: Int): PrintResult {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress(host, port), timeoutMs)
                socket.soTimeout = timeoutMs
                socket.getOutputStream().use { output ->
                    output.write(bytes)
                    output.flush()
                }
            }
            PrintResult.Success
        } catch (throwable: Throwable) {
            PrintResult.Failure("Network print failed: ${throwable.message ?: "Unknown error"}", throwable)
        }
    }
}

actual fun platformPrintingModule(): Module = module {
    single<PrinterService> { AndroidNetworkPrinterService() }
}
