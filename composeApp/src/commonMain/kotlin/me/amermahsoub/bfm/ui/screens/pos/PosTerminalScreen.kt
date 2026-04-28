package me.amermahsoub.bfm.ui.screens.pos

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.Monitor
import compose.icons.feathericons.RefreshCw
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.models.PosTerminal
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Shift
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSuccess
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.pos.PosViewModel
import org.koin.compose.koinInject

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PosTerminalScreen(
    onShiftOpened: (shiftId: Int) -> Unit,
    onBack: () -> Unit,
) {
    val viewModel: PosViewModel = koinInject()
    val terminalsState by viewModel.terminals.collectAsState()
    val currentShift by viewModel.currentShift.collectAsState()

    // Which terminal the user has tapped and is waiting on shift lookup
    var pendingTerminal by remember { mutableStateOf<PosTerminal?>(null) }
    // Dialog state: null = hidden, non-null = show open-shift dialog for this terminal
    var showOpenShiftFor by remember { mutableStateOf<PosTerminal?>(null) }

    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.loadTerminals()
        viewModel.loadSupportingData()
    }

    // Once we have loaded the shift for a pending terminal, route accordingly
    LaunchedEffect(currentShift, pendingTerminal) {
        val terminal = pendingTerminal ?: return@LaunchedEffect
        val shift = currentShift
        if (shift != null && shift.terminalId == terminal.id && shift.isOpen) {
            pendingTerminal = null
            onShiftOpened(shift.id)
        } else if (shift == null || shift.terminalId != terminal.id || shift.isClosed) {
            showOpenShiftFor = terminal
            pendingTerminal = null
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("POS Terminals", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.loadTerminals() }) {
                        Icon(FeatherIcons.RefreshCw, contentDescription = "Refresh", modifier = Modifier.size(18.dp))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { paddingValues ->
        when (val state = terminalsState) {
            is Result.Loading -> LoadingScreen("Loading terminals…")
            is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadTerminals() })
            is Result.Success -> {
                val terminals = state.data
                if (terminals.isEmpty()) {
                    EmptyView("No POS terminals configured")
                } else {
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues)
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        item { Spacer(Modifier.height(8.dp)) }
                        items(terminals, key = { it.id }) { terminal ->
                            TerminalCard(
                                terminal = terminal,
                                onClick = {
                                    scope.launch {
                                        pendingTerminal = terminal
                                        viewModel.loadCurrentShift(terminal.id)
                                    }
                                },
                            )
                        }
                        item { Spacer(Modifier.height(16.dp)) }
                    }
                }
            }
        }
    }

    // Open-shift dialog
    val dialogTerminal = showOpenShiftFor
    if (dialogTerminal != null) {
        OpenShiftDialog(
            terminalName = dialogTerminal.name,
            onConfirm = { openingCash, notes ->
                showOpenShiftFor = null
                scope.launch {
                    viewModel.openShift(dialogTerminal.id, openingCash, notes)
                }
            },
            onDismiss = { showOpenShiftFor = null },
        )
    }
}

@Composable
private fun TerminalCard(
    terminal: PosTerminal,
    onClick: () -> Unit,
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    FeatherIcons.Monitor,
                    contentDescription = null,
                    tint = OperixPrimary,
                    modifier = Modifier.size(28.dp),
                )
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(terminal.name, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    Text(
                        "Slot #${terminal.slotNumber}",
                        color = OperixTextSecondary,
                        fontSize = 13.sp,
                    )
                    terminal.drawerAccount?.let { account ->
                        Text(
                            "Drawer: ${account.name}",
                            color = OperixTextSecondary,
                            fontSize = 12.sp,
                        )
                    }
                }
            }
            Column(
                horizontalAlignment = Alignment.End,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                StatusBadge(if (terminal.isActive) "active" else "inactive")
                Text(
                    "Tap to enter",
                    color = OperixPrimary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                )
            }
        }
    }
}

@Composable
private fun OpenShiftDialog(
    terminalName: String,
    onConfirm: (openingCash: Double, notes: String?) -> Unit,
    onDismiss: () -> Unit,
) {
    var cashInput by remember { mutableStateOf("0.00") }
    var notesInput by remember { mutableStateOf("") }
    var inputError by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Open Shift — $terminalName", fontWeight = FontWeight.SemiBold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    "Enter the opening cash amount to start a new shift on this terminal.",
                    color = OperixTextSecondary,
                    fontSize = 14.sp,
                )
                OutlinedTextField(
                    value = cashInput,
                    onValueChange = {
                        cashInput = it
                        inputError = null
                    },
                    label = { Text("Opening Cash") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = inputError != null,
                    supportingText = inputError?.let { { Text(it, color = MaterialTheme.colorScheme.error) } },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = notesInput,
                    onValueChange = { notesInput = it },
                    label = { Text("Notes (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3,
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amount = cashInput.toDoubleOrNull()
                    if (amount == null || amount < 0) {
                        inputError = "Enter a valid cash amount"
                        return@Button
                    }
                    onConfirm(amount, notesInput.takeIf { it.isNotBlank() })
                },
                colors = ButtonDefaults.buttonColors(containerColor = OperixSuccess),
            ) {
                Text("Open Shift")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}
