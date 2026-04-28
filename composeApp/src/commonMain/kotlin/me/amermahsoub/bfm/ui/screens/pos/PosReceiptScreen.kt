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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.CheckCircle
import compose.icons.feathericons.Printer
import compose.icons.feathericons.ShoppingBag
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.PosOrder
import me.amermahsoub.bfm.shared.data.models.PosOrderItem
import me.amermahsoub.bfm.shared.data.models.PosOrderPayment
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.printing.EscPosBuilder
import me.amermahsoub.bfm.shared.printing.PrintPayload
import me.amermahsoub.bfm.shared.printing.PrintResult
import me.amermahsoub.bfm.shared.printing.PrinterConfig
import me.amermahsoub.bfm.shared.printing.PrinterService
import me.amermahsoub.bfm.shared.printing.PrinterTarget
import me.amermahsoub.bfm.shared.printing.Receipt
import me.amermahsoub.bfm.shared.printing.ReceiptItem
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSuccess
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import org.koin.compose.koinInject

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PosReceiptScreen(
    orderId: Int,
    onNewSale: () -> Unit,
) {
    val api: OperixApiService = koinInject()
    val sessionStore: SessionStore = koinInject()
    val printerService: PrinterService = koinInject()

    val slug = sessionStore.session.value?.login?.tenant?.slug ?: ""
    val tenantName = sessionStore.session.value?.login?.tenant?.name ?: "Operix"
    val cashierName = sessionStore.session.value?.me?.name

    var order by remember { mutableStateOf<PosOrder?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var loadError by remember { mutableStateOf<String?>(null) }
    var isPrinting by remember { mutableStateOf(false) }

    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    LaunchedEffect(orderId) {
        isLoading = true
        loadError = null
        try {
            order = api.getPosOrder(slug, orderId)
        } catch (e: Exception) {
            loadError = e.message ?: "Failed to load order"
        } finally {
            isLoading = false
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Receipt", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onNewSale) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
        containerColor = MaterialTheme.colorScheme.background,
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Button(
                    onClick = {
                        val currentOrder = order ?: return@Button
                        isPrinting = true
                        scope.launch {
                            val result = printReceipt(
                                printerService = printerService,
                                order = currentOrder,
                                tenantName = tenantName,
                                cashierName = cashierName,
                            )
                            isPrinting = false
                            when (result) {
                                is PrintResult.Success -> snackbar.showSnackbar("Receipt printed successfully")
                                is PrintResult.Failure -> snackbar.showSnackbar("Print failed: ${result.message}")
                            }
                        }
                    },
                    enabled = order != null && !isPrinting,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
                ) {
                    Icon(FeatherIcons.Printer, contentDescription = null, modifier = Modifier.size(18.dp))
                    Text(if (isPrinting) "Printing…" else "Print Receipt", modifier = Modifier.padding(start = 8.dp))
                }
                OutlinedButton(
                    onClick = onNewSale,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(FeatherIcons.ShoppingBag, contentDescription = null, modifier = Modifier.size(18.dp))
                    Text("New Sale", modifier = Modifier.padding(start = 8.dp))
                }
            }
        },
    ) { paddingValues ->
        when {
            isLoading -> LoadingScreen("Loading receipt…")
            loadError != null -> {
                Column(
                    modifier = Modifier.fillMaxSize().padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Text(loadError ?: "Error", color = OperixError)
                }
            }
            order != null -> {
                val currentOrder = order!!
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(horizontal = 16.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Spacer(Modifier.height(8.dp))

                    // Success badge
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(
                            FeatherIcons.CheckCircle,
                            contentDescription = null,
                            tint = OperixSuccess,
                            modifier = Modifier.size(48.dp),
                        )
                        Text("Order Completed", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = OperixSuccess)
                    }

                    // Order header
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("Order #", color = OperixTextSecondary, fontSize = 13.sp)
                                Text(currentOrder.orderNumber ?: currentOrder.id.toString(), fontWeight = FontWeight.SemiBold)
                            }
                            currentOrder.createdAt?.let { date ->
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                    Text("Date", color = OperixTextSecondary, fontSize = 13.sp)
                                    Text(date.take(16))
                                }
                            }
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("Status", color = OperixTextSecondary, fontSize = 13.sp)
                                StatusBadge(currentOrder.status)
                            }
                        }
                    }

                    // Items table
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    ) {
                        Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                            Text("Items", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                            Spacer(Modifier.height(10.dp))
                            // Header row
                            Row(Modifier.fillMaxWidth()) {
                                Text("Product", Modifier.weight(1f), color = OperixTextSecondary, fontSize = 12.sp)
                                Text("Qty", Modifier.padding(horizontal = 8.dp), color = OperixTextSecondary, fontSize = 12.sp, textAlign = TextAlign.End)
                                Text("Total", color = OperixTextSecondary, fontSize = 12.sp, textAlign = TextAlign.End)
                            }
                            HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))
                            currentOrder.items.forEach { item ->
                                OrderItemRow(item)
                            }
                        }
                    }

                    // Totals card
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    ) {
                        Column(
                            modifier = Modifier.fillMaxWidth().padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            ReceiptTotalsRow("Subtotal", currentOrder.subtotal)
                            if (currentOrder.discount != "0.00") {
                                ReceiptTotalsRow("Discount", "-${currentOrder.discount}", color = OperixError)
                            }
                            if (currentOrder.taxTotal != "0.00") {
                                ReceiptTotalsRow("Tax", currentOrder.taxTotal)
                            }
                            HorizontalDivider()
                            ReceiptTotalsRow("Total", currentOrder.total, bold = true, color = OperixPrimary)
                        }
                    }

                    // Payments card
                    if (currentOrder.payments.isNotEmpty()) {
                        Card(
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                        ) {
                            Column(
                                modifier = Modifier.fillMaxWidth().padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Text("Payments", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                                Spacer(Modifier.height(4.dp))
                                currentOrder.payments.forEach { payment ->
                                    PaymentRow(payment)
                                }
                            }
                        }
                    }

                    Spacer(Modifier.height(16.dp))
                }
            }
        }
    }
}

@Composable
private fun OrderItemRow(item: PosOrderItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            item.product?.name ?: "Product #${item.productId}",
            modifier = Modifier.weight(1f),
            fontSize = 13.sp,
            maxLines = 2,
        )
        Text(
            item.quantity,
            modifier = Modifier.padding(horizontal = 8.dp),
            fontSize = 13.sp,
            textAlign = TextAlign.End,
            color = OperixTextSecondary,
        )
        Text(
            item.total,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.End,
            color = OperixPrimary,
        )
    }
}

@Composable
private fun ReceiptTotalsRow(
    label: String,
    value: String,
    bold: Boolean = false,
    color: Color = Color.Unspecified,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            label,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            fontSize = if (bold) 15.sp else 13.sp,
            color = OperixTextSecondary,
        )
        Text(
            value,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Medium,
            fontSize = if (bold) 15.sp else 13.sp,
            color = if (color != Color.Unspecified) color else MaterialTheme.colorScheme.onSurface,
        )
    }
}

@Composable
private fun PaymentRow(payment: PosOrderPayment) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            payment.paymentMethod?.let { it.nameEn ?: it.type } ?: "Payment #${payment.paymentMethodId}",
            fontSize = 13.sp,
            color = OperixTextSecondary,
        )
        Text(payment.amount, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}

private suspend fun printReceipt(
    printerService: PrinterService,
    order: PosOrder,
    tenantName: String,
    cashierName: String?,
): PrintResult {
    val now: LocalDateTime = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault())

    val receiptItems = order.items.map { item ->
        ReceiptItem(
            name = item.product?.name ?: "Item #${item.productId}",
            qty = item.quantity,
            unitPriceCents = ((item.unitPrice.toDoubleOrNull() ?: 0.0) * 100).toLong(),
            totalLineCents = ((item.total.toDoubleOrNull() ?: 0.0) * 100).toLong(),
        )
    }

    // Resolve primary payment method for the printing model
    val primaryPayment = order.payments.firstOrNull()
    val printPaymentMethod = when ((primaryPayment?.paymentMethod?.let { it.nameEn ?: it.type })?.lowercase()) {
        "cash" -> me.amermahsoub.bfm.shared.printing.PaymentMethod.CASH
        "visa", "card", "credit_card", "debit_card" -> me.amermahsoub.bfm.shared.printing.PaymentMethod.VISA
        else -> me.amermahsoub.bfm.shared.printing.PaymentMethod.CASH
    }

    val receipt = Receipt(
        storeName = tenantName,
        storeAddress = "",
        cashierName = cashierName,
        invoiceNumber = order.orderNumber ?: order.id.toString(),
        dateTime = now,
        items = receiptItems,
        subtotalCents = ((order.subtotal.toDoubleOrNull() ?: 0.0) * 100).toLong(),
        discountCents = ((order.discount.toDoubleOrNull() ?: 0.0) * 100).toLong(),
        taxCents = ((order.taxTotal.toDoubleOrNull() ?: 0.0) * 100).toLong(),
        totalCents = ((order.total.toDoubleOrNull() ?: 0.0) * 100).toLong(),
        paymentMethod = printPaymentMethod,
        paidAmountCents = order.payments.sumOf { ((it.amount.toDoubleOrNull() ?: 0.0) * 100).toLong() },
        footerMessage = "Thank you for your business!",
    )

    val bytes = EscPosBuilder(PrinterConfig()).buildReceipt(receipt)

    // Default to localhost:9100; in production retrieve host/port from tenant printer config
    return printerService.print(PrintPayload(target = PrinterTarget.Network("127.0.0.1", 9100), bytes = bytes))
}
