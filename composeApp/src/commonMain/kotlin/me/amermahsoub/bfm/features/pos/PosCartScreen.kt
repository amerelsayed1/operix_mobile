package me.amermahsoub.bfm.features.pos

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilterChip
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.BadgeTone
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.StatusBadge
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import org.koin.core.context.GlobalContext

@Composable
fun PosCartScreen(
    onOpenShift: () -> Unit,
    onCloseShift: () -> Unit,
    onOrderPlaced: (Long) -> Unit,
    onViewOrders: () -> Unit,
) {
    val koin = GlobalContext.get()
    val repo = remember { koin.get<PosRepository>() }
    val sessionStore = remember { koin.get<SessionStore>() }
    val session by sessionStore.session.collectAsState()
    val defaultInventoryId = session?.tenantConfig?.defaultInventoryId
    val vm = rememberFeatureViewModel { PosCartViewModel(repo, defaultInventoryId) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.submittedOrderId) {
        state.submittedOrderId?.let { id ->
            vm.acknowledgeSubmitted()
            onOrderPlaced(id)
        }
    }

    when {
        state.loading -> LoadingState()
        state.error != null && state.shift == null && state.reference.products.isEmpty() ->
            ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(strings.posTitle)

                // Shift banner
                val shiftOpen = state.shift?.status == "open"
                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            val tone = if (shiftOpen) BadgeTone.SUCCESS else BadgeTone.WARNING
                            StatusBadge(
                                text = if (shiftOpen) strings.shiftOpen else strings.shiftClosed,
                                tone = tone,
                            )
                            state.shift?.openedAt?.let {
                                Spacer(Modifier.height(4.dp))
                                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        if (shiftOpen) {
                            SecondaryButton(text = strings.closeShift, onClick = onCloseShift, modifier = Modifier)
                        } else {
                            PrimaryButton(text = strings.openShift, onClick = onOpenShift, modifier = Modifier)
                        }
                    }
                }

                // Search
                OutlinedTextField(
                    value = state.searchQuery,
                    onValueChange = vm::updateSearch,
                    label = { Text(strings.searchProducts) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                if (state.searchResults.isNotEmpty()) {
                    SectionTitle(strings.productsTitle)
                    state.searchResults.take(10).forEach { product ->
                        ElevatedCard(
                            onClick = { vm.addToCart(product) },
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp).fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(product.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                                    val sub = product.sku ?: product.category ?: ""
                                    if (sub.isNotBlank()) {
                                        Text(
                                            sub,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        )
                                    }
                                }
                                Text(product.displayPrice, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }

                // Cart
                SectionTitle(strings.cart)
                if (state.lines.isEmpty()) {
                    Text(strings.emptyCart, style = MaterialTheme.typography.bodyMedium)
                } else {
                    state.lines.forEach { line ->
                        ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                            Row(
                                modifier = Modifier.padding(12.dp).fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(line.product.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                                    Text(
                                        "${line.quantity} × ${line.product.displayPrice}",
                                        style = MaterialTheme.typography.bodySmall,
                                    )
                                }
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    IconButton(onClick = { vm.setQuantity(line.product.id, line.quantity - 1.0) }) {
                                        Text("-", style = MaterialTheme.typography.titleLarge)
                                    }
                                    Text(line.quantity.toInt().toString(), style = MaterialTheme.typography.titleMedium)
                                    IconButton(onClick = { vm.setQuantity(line.product.id, line.quantity + 1.0) }) {
                                        Text("+", style = MaterialTheme.typography.titleLarge)
                                    }
                                }
                                Text(
                                    line.lineTotal.format2(),
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                )
                            }
                        }
                    }
                }

                // Totals
                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        TotalRow(strings.subtotal, state.subtotal.format2())
                        TotalRow(strings.discount, "-${state.discountValue.format2()}")
                        TotalRow(strings.tax, state.taxTotal.format2())
                        Spacer(Modifier.height(6.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(strings.grandTotal, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                            Text(state.grandTotal.format2(), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                // Payment method
                if (state.reference.paymentMethods.isNotEmpty()) {
                    SectionTitle(strings.paymentMethod)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        state.reference.paymentMethods.filter { it.isActive }.forEach { pm ->
                            FilterChip(
                                selected = state.selectedPaymentMethod?.id == pm.id,
                                onClick = { vm.selectPaymentMethod(pm) },
                                label = { Text(pm.name) },
                            )
                        }
                    }
                }

                // Drawer account (only if needed)
                if (state.selectedPaymentMethod?.requiresAccount == true && state.reference.accounts.isNotEmpty()) {
                    SectionTitle(strings.drawerAccount)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        state.reference.accounts.forEach { acc ->
                            FilterChip(
                                selected = state.selectedAccount?.id == acc.id,
                                onClick = { vm.selectAccount(acc) },
                                label = { Text(acc.name) },
                            )
                        }
                    }
                }

                // Discount input
                OutlinedTextField(
                    value = if (state.discountValue == 0.0) "" else state.discountValue.format2(),
                    onValueChange = vm::updateDiscount,
                    label = { Text(strings.discount) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                // Tax picker
                if (state.reference.taxes.isNotEmpty()) {
                    SectionTitle(strings.tax)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(
                            selected = state.selectedTax == null,
                            onClick = { vm.selectTax(null) },
                            label = { Text(strings.no) },
                        )
                        state.reference.taxes.forEach { tax ->
                            FilterChip(
                                selected = state.selectedTax?.id == tax.id,
                                onClick = { vm.selectTax(tax) },
                                label = { Text("${tax.name} (${tax.rate}%)") },
                            )
                        }
                    }
                }

                state.error?.let { err ->
                    Text(err.message, color = MaterialTheme.colorScheme.error)
                }

                if (!shiftOpen && state.lines.isNotEmpty()) {
                    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            StatusBadge(strings.shiftClosed, tone = BadgeTone.WARNING)
                            Spacer(Modifier.height(8.dp))
                            Text(
                                strings.openShift,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Spacer(Modifier.height(8.dp))
                            PrimaryButton(text = strings.openShift, onClick = onOpenShift)
                        }
                    }
                }

                PrimaryButton(
                    text = if (state.submitting) strings.loading else strings.completeSale,
                    onClick = { vm.checkout() },
                    enabled = state.canCheckout,
                )

                SecondaryButton(text = strings.orders, onClick = onViewOrders)
            }
        }
    }
}

@Composable
private fun TotalRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodyMedium)
    }
}

private fun Double.format2(): String {
    val cents = (this * 100).toLong()
    val whole = cents / 100
    val frac = (if (cents < 0) -cents else cents) % 100
    val fracStr = if (frac < 10) "0$frac" else frac.toString()
    return "$whole.$fracStr"
}
