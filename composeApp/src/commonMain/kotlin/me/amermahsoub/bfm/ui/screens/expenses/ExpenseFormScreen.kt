package me.amermahsoub.bfm.ui.screens.expenses

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
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
import compose.icons.feathericons.ChevronDown
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.models.ExpenseCategory
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.expenses.ExpenseViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpenseFormScreen(onSaved: () -> Unit, onBack: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ExpenseViewModel(
            api = koin.get(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val categories by viewModel.categories.collectAsState()
    val paymentMethods by viewModel.paymentMethods.collectAsState()
    val scope = rememberCoroutineScope()

    var selectedCategory by remember { mutableStateOf<ExpenseCategory?>(null) }
    var selectedPaymentMethod by remember { mutableStateOf<PaymentMethod?>(null) }
    var amount by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var expenseDate by remember { mutableStateOf("") }
    var reference by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    var categoryExpanded by remember { mutableStateOf(false) }
    var paymentExpanded by remember { mutableStateOf(false) }

    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Pre-select defaults when data loads
    if (selectedCategory == null && categories.isNotEmpty()) {
        selectedCategory = categories.firstOrNull { it.isDefault } ?: categories.first()
    }
    if (selectedPaymentMethod == null && paymentMethods.isNotEmpty()) {
        selectedPaymentMethod = paymentMethods.first()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Expense", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                ),
            )
        },
        containerColor = OperixSurface,
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Category dropdown
            FormLabel("Category")
            DropdownField(
                value = selectedCategory?.displayName() ?: "Select category",
                expanded = categoryExpanded,
                onExpand = { categoryExpanded = true },
                onDismiss = { categoryExpanded = false },
            ) {
                categories.forEach { cat ->
                    DropdownMenuItem(
                        text = { Text(cat.displayName()) },
                        onClick = {
                            selectedCategory = cat
                            categoryExpanded = false
                        },
                    )
                }
            }

            // Amount
            FormLabel("Amount")
            OutlinedTextField(
                value = amount,
                onValueChange = { amount = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("0.00") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                shape = RoundedCornerShape(10.dp),
            )

            // Description
            FormLabel("Description")
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Enter description") },
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            // Payment method dropdown
            FormLabel("Payment Method")
            DropdownField(
                value = selectedPaymentMethod?.displayName() ?: "Select payment method",
                expanded = paymentExpanded,
                onExpand = { paymentExpanded = true },
                onDismiss = { paymentExpanded = false },
            ) {
                paymentMethods.forEach { method ->
                    DropdownMenuItem(
                        text = { Text(method.displayName()) },
                        onClick = {
                            selectedPaymentMethod = method
                            paymentExpanded = false
                        },
                    )
                }
            }

            // Date
            FormLabel("Date")
            OutlinedTextField(
                value = expenseDate,
                onValueChange = { expenseDate = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("YYYY-MM-DD") },
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            // Reference (optional)
            FormLabel("Reference / Receipt #  (optional)")
            OutlinedTextField(
                value = reference,
                onValueChange = { reference = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("e.g. REC-001") },
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            // Notes (optional)
            FormLabel("Notes  (optional)")
            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Additional notes…") },
                minLines = 2,
                maxLines = 4,
                shape = RoundedCornerShape(10.dp),
            )

            if (errorMessage != null) {
                Text(errorMessage!!, color = OperixError, fontSize = 13.sp)
            }

            Spacer(Modifier.height(8.dp))

            Button(
                onClick = {
                    val cat = selectedCategory
                    val pm = selectedPaymentMethod
                    val amt = amount.toDoubleOrNull()

                    when {
                        cat == null -> errorMessage = "Please select a category"
                        amt == null || amt <= 0 -> errorMessage = "Enter a valid amount"
                        description.isBlank() -> errorMessage = "Description is required"
                        pm == null -> errorMessage = "Please select a payment method"
                        expenseDate.isBlank() -> errorMessage = "Date is required"
                        else -> {
                            errorMessage = null
                            isSubmitting = true
                            scope.launch {
                                val result = viewModel.createExpense(
                                    categoryId = cat.id,
                                    amount = amt,
                                    paymentMethodId = pm.id,
                                    date = expenseDate,
                                    description = description,
                                    reference = reference.takeIf { it.isNotBlank() },
                                    notes = notes.takeIf { it.isNotBlank() },
                                )
                                isSubmitting = false
                                when (result) {
                                    is Result.Success -> onSaved()
                                    is Result.Error -> errorMessage = result.message
                                    else -> Unit
                                }
                            }
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                enabled = !isSubmitting,
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(modifier = Modifier.size(22.dp), color = Color.White, strokeWidth = 2.5.dp)
                } else {
                    Text("Save Expense", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun FormLabel(text: String) {
    Text(text, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = OperixTextSecondary)
}

@Composable
private fun DropdownField(
    value: String,
    expanded: Boolean,
    onExpand: () -> Unit,
    onDismiss: () -> Unit,
    content: @Composable () -> Unit,
) {
    Box {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(10.dp))
                .clickable { onExpand() }
                .padding(horizontal = 16.dp, vertical = 14.dp),
            color = Color.White,
            shape = RoundedCornerShape(10.dp),
        ) {
            androidx.compose.foundation.layout.Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(value, fontSize = 14.sp, modifier = Modifier.weight(1f))
                Icon(FeatherIcons.ChevronDown, contentDescription = null, tint = OperixTextSecondary, modifier = Modifier.size(16.dp))
            }
        }
        DropdownMenu(expanded = expanded, onDismissRequest = onDismiss) {
            content()
        }
    }
}
