package me.amermahsoub.bfm.ui.screens.invoices.purchases

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
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
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.InvoiceItem
import me.amermahsoub.bfm.shared.data.models.InvoicePayment
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.PurchaseInvoice
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.invoices.PurchaseInvoiceViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PurchaseInvoiceDetailScreen(
    invoiceId: Int,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        PurchaseInvoiceViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val invoiceState by viewModel.invoiceDetail.collectAsState()
    val paymentMethods by viewModel.paymentMethods.collectAsState()
    val scope = rememberCoroutineScope()

    var showPaymentDialog by remember { mutableStateOf(false) }
    var actionError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(invoiceId) {
        viewModel.loadInvoice(invoiceId)
        viewModel.loadFormData()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Purchase Invoice", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        containerColor = OperixSurface,
    ) { innerPadding ->
        when (val state = invoiceState) {
            is Result.Loading -> LoadingScreen()
            is Result.Error -> ErrorView(
                message = state.message,
                onRetry = { viewModel.loadInvoice(invoiceId) },
            )
            is Result.Success -> {
                val invoice = state.data

                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(innerPadding),
                    contentPadding = PaddingValues(bottom = 32.dp),
                ) {
                    // Header card
                    item {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            elevation = CardDefaults.cardElevation(2.dp),
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Text(
                                        text = invoice.invoiceNumber,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 18.sp,
                                    )
                                    StatusBadge(status = invoice.status)
                                }
                                Spacer(Modifier.height(8.dp))
                                PurchaseLabelValue("Invoice Date", invoice.invoiceDate)
                                val invoiceDueDate = invoice.dueDate
                                if (invoiceDueDate != null) {
                                    PurchaseLabelValue("Due Date", invoiceDueDate)
                                }
                                val invoiceSupplierInvoiceNumber = invoice.supplierInvoiceNumber
                                if (invoiceSupplierInvoiceNumber != null) {
                                    PurchaseLabelValue("Supplier Ref", invoiceSupplierInvoiceNumber)
                                }
                            }
                        }
                    }

                    // Supplier section
                    item {
                        SectionHeader(title = "Supplier")
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            elevation = CardDefaults.cardElevation(1.dp),
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                val invoiceSupplier = invoice.supplier
                                Text(
                                    text = invoiceSupplier?.companyName ?: "—",
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 15.sp,
                                )
                                if (invoiceSupplier != null) {
                                    Spacer(Modifier.height(4.dp))
                                    Text(
                                        text = "Payable Balance: ${invoiceSupplier.payableBalance}",
                                        color = OperixTextSecondary,
                                        fontSize = 13.sp,
                                    )
                                    if (invoiceSupplier.contactName != null) {
                                        Text(
                                            text = "Contact: ${invoiceSupplier.contactName}",
                                            color = OperixTextSecondary,
                                            fontSize = 13.sp,
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Items section
                    item { SectionHeader(title = "Items") }
                    item {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            elevation = CardDefaults.cardElevation(1.dp),
                        ) {
                            Column(modifier = Modifier.padding(vertical = 4.dp)) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp, vertical = 8.dp),
                                ) {
                                    Text(
                                        "Product",
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 12.sp,
                                        modifier = Modifier.weight(2f),
                                        color = OperixTextSecondary,
                                    )
                                    Text(
                                        "Qty",
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 12.sp,
                                        modifier = Modifier.weight(1f),
                                        color = OperixTextSecondary,
                                    )
                                    Text(
                                        "Cost",
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 12.sp,
                                        modifier = Modifier.weight(1f),
                                        color = OperixTextSecondary,
                                    )
                                    Text(
                                        "Total",
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 12.sp,
                                        modifier = Modifier.weight(1f),
                                        color = OperixTextSecondary,
                                    )
                                }
                                Divider()
                                invoice.items.forEachIndexed { index, item ->
                                    PurchaseItemRow(item)
                                    if (index < invoice.items.lastIndex) {
                                        Divider(modifier = Modifier.padding(horizontal = 16.dp))
                                    }
                                }
                            }
                        }
                    }

                    // Totals section
                    item {
                        SectionHeader(title = "Totals")
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            elevation = CardDefaults.cardElevation(1.dp),
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                PurchaseTotalRow("Subtotal", invoice.subtotal)
                                if (invoice.discount != "0.00" && invoice.discount != "0") {
                                    PurchaseTotalRow("Discount", "-${invoice.discount}", negative = true)
                                }
                                if (invoice.taxTotal != "0.00" && invoice.taxTotal != "0") {
                                    PurchaseTotalRow("Tax", invoice.taxTotal)
                                }
                                Divider(modifier = Modifier.padding(vertical = 8.dp))
                                PurchaseTotalRow("Total", invoice.total, bold = true)
                                PurchaseTotalRow("Paid", invoice.paidAmount)
                                if (invoice.remainingAmount != "0.00") {
                                    PurchaseTotalRow("Remaining", invoice.remainingAmount, negative = true)
                                }
                            }
                        }
                    }

                    // Payments section
                    if (invoice.payments.isNotEmpty()) {
                        item { SectionHeader(title = "Payments") }
                        items(invoice.payments, key = { it.id }) { payment ->
                            PurchasePaymentRow(payment)
                        }
                    }

                    // Action error
                    if (actionError != null) {
                        item {
                            Text(
                                text = actionError!!,
                                color = OperixError,
                                fontSize = 13.sp,
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                            )
                        }
                    }

                    // Action buttons
                    item {
                        Spacer(Modifier.height(16.dp))
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            // Post Invoice (draft only)
                            if (invoice.status == "draft") {
                                Button(
                                    onClick = {
                                        scope.launch {
                                            actionError = null
                                            val result = viewModel.postInvoice(invoice.id)
                                            if (result is Result.Error) actionError = result.message
                                            else viewModel.loadInvoice(invoiceId)
                                        }
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(10.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
                                ) {
                                    Text("Post Invoice")
                                }
                            }

                            // Record Payment (posted or partial)
                            if (invoice.status == "posted" || invoice.status == "partial") {
                                Button(
                                    onClick = { showPaymentDialog = true },
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(10.dp),
                                ) {
                                    Text("Record Payment")
                                }
                            }
                        }
                    }
                }

                // Record Payment Dialog
                if (showPaymentDialog) {
                    PurchaseRecordPaymentDialog(
                        paymentMethods = paymentMethods,
                        onDismiss = { showPaymentDialog = false },
                        onConfirm = { amount, methodId, date, notes ->
                            scope.launch {
                                actionError = null
                                val result = viewModel.recordSupplierPayment(
                                    invoiceId, amount, methodId, date, notes,
                                )
                                if (result is Result.Error) actionError = result.message
                                else {
                                    viewModel.loadInvoice(invoiceId)
                                    showPaymentDialog = false
                                }
                            }
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun PurchaseItemRow(item: InvoiceItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = item.product?.name ?: "Product #${item.productId}",
            fontSize = 13.sp,
            modifier = Modifier.weight(2f),
        )
        Text(
            text = item.quantity,
            fontSize = 13.sp,
            modifier = Modifier.weight(1f),
            color = OperixTextSecondary,
        )
        Text(
            text = item.unitPrice,
            fontSize = 13.sp,
            modifier = Modifier.weight(1f),
            color = OperixTextSecondary,
        )
        Text(
            text = item.total,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun PurchaseTotalRow(
    label: String,
    amount: String,
    bold: Boolean = false,
    negative: Boolean = false,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = label,
            fontSize = 14.sp,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = if (bold) MaterialTheme.colorScheme.onSurface else OperixTextSecondary,
        )
        Text(
            text = amount,
            fontSize = 14.sp,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.SemiBold,
            color = if (negative) OperixError else if (bold) OperixPrimary else MaterialTheme.colorScheme.onSurface,
        )
    }
}

@Composable
private fun PurchasePaymentRow(payment: InvoicePayment) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(1.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text(
                    text = payment.paymentMethod?.nameEn ?: "Payment",
                    fontWeight = FontWeight.Medium,
                    fontSize = 13.sp,
                )
                Text(
                    text = payment.paymentDate,
                    color = OperixTextSecondary,
                    fontSize = 12.sp,
                )
            }
            AmountText(amount = payment.amount, positive = true)
        }
    }
}

@Composable
private fun PurchaseLabelValue(label: String, value: String) {
    Row(modifier = Modifier.padding(vertical = 2.dp)) {
        Text(text = "$label: ", color = OperixTextSecondary, fontSize = 13.sp)
        Text(text = value, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PurchaseRecordPaymentDialog(
    paymentMethods: List<PaymentMethod>,
    onDismiss: () -> Unit,
    onConfirm: (amount: Double, methodId: Int, date: String, notes: String?) -> Unit,
) {
    var amount by remember { mutableStateOf("") }
    var selectedMethod by remember { mutableStateOf<PaymentMethod?>(paymentMethods.firstOrNull()) }
    var date by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var methodDropdownExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Record Supplier Payment", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it },
                    label = { Text("Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(10.dp),
                    singleLine = true,
                )

                ExposedDropdownMenuBox(
                    expanded = methodDropdownExpanded,
                    onExpandedChange = { methodDropdownExpanded = it },
                ) {
                    OutlinedTextField(
                        value = selectedMethod?.displayName() ?: "Select method",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Payment Method") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(methodDropdownExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable),
                        shape = RoundedCornerShape(10.dp),
                    )
                    ExposedDropdownMenu(
                        expanded = methodDropdownExpanded,
                        onDismissRequest = { methodDropdownExpanded = false },
                    ) {
                        paymentMethods.forEach { method ->
                            DropdownMenuItem(
                                text = { Text(method.displayName()) },
                                onClick = {
                                    selectedMethod = method
                                    methodDropdownExpanded = false
                                },
                            )
                        }
                    }
                }

                OutlinedTextField(
                    value = date,
                    onValueChange = { date = it },
                    label = { Text("Payment Date (YYYY-MM-DD)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    singleLine = true,
                )

                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    maxLines = 2,
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amountDouble = amount.toDoubleOrNull() ?: return@Button
                    val method = selectedMethod ?: return@Button
                    if (date.isBlank()) return@Button
                    onConfirm(amountDouble, method.id, date, notes.ifBlank { null })
                },
                colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
            ) {
                Text("Confirm")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
        shape = RoundedCornerShape(16.dp),
    )
}
