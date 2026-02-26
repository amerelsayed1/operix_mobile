package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.printing.EscPosBuilder
import me.amermahsoub.bfm.shared.printing.PrintPayload
import me.amermahsoub.bfm.shared.printing.PrintResult
import me.amermahsoub.bfm.shared.printing.PrinterConfig
import me.amermahsoub.bfm.shared.printing.PrinterService
import me.amermahsoub.bfm.shared.printing.PrinterTarget
import me.amermahsoub.bfm.shared.printing.TestReceiptFactory
import me.amermahsoub.bfm.shared.printing.printingModule
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun App() {
    initializeKoinIfNeeded()
    val printerService = remember { GlobalContext.get().koin.get<PrinterService>() }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    var host by remember { mutableStateOf("192.168.1.100") }
    var portInput by remember { mutableStateOf("9100") }
    var widthInput by remember { mutableStateOf("42") }

    MaterialTheme {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
        ) { padding ->
            Column(
                modifier = Modifier
                    .padding(padding)
                    .safeContentPadding()
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text("Network ESC/POS Test", style = MaterialTheme.typography.headlineSmall)
                OutlinedTextField(
                    value = host,
                    onValueChange = { host = it },
                    label = { Text("Printer Host") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = portInput,
                    onValueChange = { portInput = it.filter { c -> c.isDigit() } },
                    label = { Text("Printer Port") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = widthInput,
                    onValueChange = { widthInput = it.filter { c -> c.isDigit() } },
                    label = { Text("Paper Width (32/42/48)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = {
                        scope.launch {
                            val port = portInput.toIntOrNull() ?: 9_100
                            val charsPerLine = widthInput.toIntOrNull()?.takeIf { it in listOf(32, 42, 48) } ?: 42
                            val bytes = EscPosBuilder(
                                PrinterConfig(charsPerLine = charsPerLine, enableCut = true, feedLinesAfter = 3),
                            ).buildReceipt(TestReceiptFactory.create())
                            val result = printerService.print(
                                PrintPayload(
                                    target = PrinterTarget.Network(host = host, port = port),
                                    bytes = bytes,
                                    timeoutMs = 5_000,
                                ),
                            )
                            val message = when (result) {
                                PrintResult.Success -> "Receipt sent successfully"
                                is PrintResult.Failure -> "Print failed: ${result.message}"
                            }
                            snackbarHostState.showSnackbar(message)
                        }
                    }) {
                        Text("Print Test Receipt")
                    }
                }
            }
        }
    }
}

private fun initializeKoinIfNeeded() {
    if (GlobalContext.getOrNull() == null) {
        startKoin {
            modules(printingModule())
        }
    }
}
