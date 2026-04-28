package me.amermahsoub.bfm.ui.screens.pos

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SheetValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.Minus
import compose.icons.feathericons.Plus
import compose.icons.feathericons.Search
import compose.icons.feathericons.ShoppingCart
import compose.icons.feathericons.Trash2
import compose.icons.feathericons.X
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.models.CartItem
import me.amermahsoub.bfm.shared.data.models.CreatePosOrderPaymentRequest
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.pos.PosViewModel
import org.koin.compose.koinInject

@OptIn(ExperimentalMaterial3Api::class, FlowPreview::class)
@Composable
fun PosScreen(
    shiftId: Int,
    onOrderCompleted: (orderId: Int) -> Unit,
    onCloseShift: () -> Unit,
) {
    val viewModel: PosViewModel = koinInject()
    val cart by viewModel.cart.collectAsState()
    val currentShift by viewModel.currentShift.collectAsState()
    val paymentMethods by viewModel.paymentMethods.collectAsState()
    val scope = rememberCoroutineScope()

    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<Product>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    var checkoutError by remember { mutableStateOf<String?>(null) }

    val cartSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    var showCartSheet by remember { mutableStateOf(false) }
    var showPaymentDialog by remember { mutableStateOf(false) }

    // Debounced product search
    val searchQueryFlow = remember { snapshotFlow { searchQuery } }
    LaunchedEffect(Unit) {
        searchQueryFlow
            .debounce(300L)
            .distinctUntilChanged()
            .collect { query ->
                if (query.isBlank()) {
                    searchResults = emptyList()
                    isSearching = false
                } else {
                    isSearching = true
                    searchResults = viewModel.searchProducts(query)
                    isSearching = false
                }
            }
    }

    val shift = currentShift
    val shiftInfo = if (shift != null) {
        "${shift.terminal?.name ?: "Terminal"} • Opened ${shift.openedAt?.take(16) ?: ""}"
    } else {
        "Shift #$shiftId"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("POS", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                        Text(shiftInfo, color = OperixTextSecondary, fontSize = 12.sp)
                    }
                },
                actions = {
                    BadgedBox(
                        badge = {
                            if (cart.isNotEmpty()) {
                                Badge { Text(cart.size.toString()) }
                            }
                        },
                    ) {
                        IconButton(onClick = { showCartSheet = true }) {
                            Icon(FeatherIcons.ShoppingCart, contentDescription = "Cart", tint = OperixPrimary)
                        }
                    }
                    TextButton(onClick = onCloseShift) {
                        Text("Close Shift", color = OperixError, fontSize = 13.sp)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
        ) {
            // Search bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search products…") },
                leadingIcon = { Icon(FeatherIcons.Search, contentDescription = null, modifier = Modifier.size(18.dp)) },
                trailingIcon = {
                    if (searchQuery.isNotBlank()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(FeatherIcons.X, contentDescription = "Clear", modifier = Modifier.size(18.dp))
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
            )

            // Product grid
            if (searchResults.isEmpty() && searchQuery.isBlank()) {
                EmptyView("Search for products to add to cart")
            } else if (isSearching) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Searching…", color = OperixTextSecondary)
                }
            } else if (searchResults.isEmpty()) {
                EmptyView("No products found for \"$searchQuery\"")
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 12.dp),
                    contentPadding = PaddingValues(bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(searchResults, key = { it.id }) { product ->
                        ProductCard(
                            product = product,
                            onAddToCart = {
                                val price = product.sellingPrice.toDoubleOrNull() ?: 0.0
                                viewModel.addToCart(product, 1.0, price)
                            },
                        )
                    }
                }
            }

            // Cart summary footer (only visible when cart not empty)
            if (cart.isNotEmpty()) {
                CartFooter(
                    itemCount = cart.size,
                    total = viewModel.cartTotal,
                    onViewCart = { showCartSheet = true },
                    onCheckout = { showPaymentDialog = true },
                )
            }
        }
    }

    // Cart bottom sheet
    if (showCartSheet) {
        ModalBottomSheet(
            onDismissRequest = { showCartSheet = false },
            sheetState = cartSheetState,
            dragHandle = { BottomSheetDefaults.DragHandle() },
        ) {
            CartBottomSheet(
                cart = cart,
                subtotal = viewModel.cartSubtotal,
                tax = viewModel.cartTax,
                total = viewModel.cartTotal,
                onQtyIncrease = { item -> viewModel.updateCartItemQty(item.productId, item.variantId, item.quantity + 1.0) },
                onQtyDecrease = { item -> viewModel.updateCartItemQty(item.productId, item.variantId, item.quantity - 1.0) },
                onRemove = { item -> viewModel.removeFromCart(item.productId, item.variantId) },
                onClear = { viewModel.clearCart() },
                onCheckout = {
                    showCartSheet = false
                    showPaymentDialog = true
                },
            )
        }
    }

    // Payment dialog
    if (showPaymentDialog) {
        PaymentDialog(
            total = viewModel.cartTotal,
            paymentMethods = paymentMethods,
            error = checkoutError,
            onConfirm = { payments ->
                checkoutError = null
                scope.launch {
                    val result = viewModel.checkout(shiftId, payments)
                    when (result) {
                        is Result.Success -> {
                            showPaymentDialog = false
                            onOrderCompleted(result.data.id)
                        }
                        is Result.Error -> checkoutError = result.message
                        is Result.Loading -> Unit
                    }
                }
            },
            onDismiss = {
                showPaymentDialog = false
                checkoutError = null
            },
        )
    }
}

@Composable
private fun ProductCard(
    product: Product,
    onAddToCart: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                product.name,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                lineHeight = 18.sp,
            )
            product.sku?.let {
                Text(it, color = OperixTextSecondary, fontSize = 11.sp)
            }
            Spacer(Modifier.weight(1f, fill = false))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                AmountText(product.sellingPrice)
                FilledIconButton(
                    onClick = onAddToCart,
                    modifier = Modifier.size(32.dp),
                    colors = IconButtonDefaults.filledIconButtonColors(containerColor = OperixPrimary),
                ) {
                    Icon(
                        FeatherIcons.Plus,
                        contentDescription = "Add to cart",
                        modifier = Modifier.size(16.dp),
                        tint = Color.White,
                    )
                }
            }
        }
    }
}

@Composable
private fun CartFooter(
    itemCount: Int,
    total: Double,
    onViewCart: () -> Unit,
    onCheckout: () -> Unit,
) {
    Divider()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text("$itemCount item${if (itemCount != 1) "s" else ""}", color = OperixTextSecondary, fontSize = 13.sp)
            Text("Total: ${"%.2f".format(total)}", fontWeight = FontWeight.Bold, fontSize = 16.sp)
        }
        TextButton(onClick = onViewCart) { Text("View Cart") }
        Button(onClick = onCheckout) { Text("Checkout") }
    }
}

@Composable
private fun CartBottomSheet(
    cart: List<CartItem>,
    subtotal: Double,
    tax: Double,
    total: Double,
    onQtyIncrease: (CartItem) -> Unit,
    onQtyDecrease: (CartItem) -> Unit,
    onRemove: (CartItem) -> Unit,
    onClear: () -> Unit,
    onCheckout: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 24.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Cart (${cart.size})", fontWeight = FontWeight.Bold, fontSize = 18.sp)
            TextButton(onClick = onClear) {
                Text("Clear all", color = OperixError, fontSize = 13.sp)
            }
        }
        HorizontalDivider()
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f, fill = false),
            contentPadding = PaddingValues(vertical = 8.dp),
        ) {
            items(cart, key = { "${it.productId}-${it.variantId}" }) { item ->
                CartItemRow(
                    item = item,
                    onIncrease = { onQtyIncrease(item) },
                    onDecrease = { onQtyDecrease(item) },
                    onRemove = { onRemove(item) },
                )
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            }
        }
        // Totals section
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            TotalsRow("Subtotal", "${"%.2f".format(subtotal)}")
            if (tax > 0.0) TotalsRow("Tax", "${"%.2f".format(tax)}")
            HorizontalDivider()
            TotalsRow("Total", "${"%.2f".format(total)}", bold = true)
        }
        Button(
            onClick = onCheckout,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
        ) {
            Text("Checkout — ${"%.2f".format(total)}", fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun CartItemRow(
    item: CartItem,
    onIncrease: () -> Unit,
    onDecrease: () -> Unit,
    onRemove: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(item.name, fontWeight = FontWeight.Medium, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(
                "${"%.2f".format(item.unitPrice)} × ${"%.1f".format(item.quantity)}",
                color = OperixTextSecondary,
                fontSize = 12.sp,
            )
        }
        Text(
            "${"%.2f".format(item.lineTotal)}",
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
            color = OperixPrimary,
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            FilledIconButton(
                onClick = onDecrease,
                modifier = Modifier.size(28.dp),
                colors = IconButtonDefaults.filledIconButtonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Icon(FeatherIcons.Minus, contentDescription = "Decrease", modifier = Modifier.size(14.dp), tint = OperixTextSecondary)
            }
            Text(
                "${"%.0f".format(item.quantity)}",
                modifier = Modifier.width(28.dp),
                textAlign = TextAlign.Center,
                fontWeight = FontWeight.Medium,
                fontSize = 14.sp,
            )
            FilledIconButton(
                onClick = onIncrease,
                modifier = Modifier.size(28.dp),
                colors = IconButtonDefaults.filledIconButtonColors(containerColor = OperixPrimary),
            ) {
                Icon(FeatherIcons.Plus, contentDescription = "Increase", modifier = Modifier.size(14.dp), tint = Color.White)
            }
        }
        IconButton(onClick = onRemove, modifier = Modifier.size(28.dp)) {
            Icon(FeatherIcons.Trash2, contentDescription = "Remove", tint = OperixError, modifier = Modifier.size(16.dp))
        }
    }
}

@Composable
private fun TotalsRow(label: String, value: String, bold: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal, fontSize = if (bold) 16.sp else 14.sp)
        Text(value, fontWeight = if (bold) FontWeight.Bold else FontWeight.SemiBold, fontSize = if (bold) 16.sp else 14.sp, color = if (bold) OperixPrimary else MaterialTheme.colorScheme.onSurface)
    }
}

@Composable
private fun PaymentDialog(
    total: Double,
    paymentMethods: List<PaymentMethod>,
    error: String?,
    onConfirm: (List<CreatePosOrderPaymentRequest>) -> Unit,
    onDismiss: () -> Unit,
) {
    // Map from paymentMethodId → amount string entered by user
    val amountInputs = remember { mutableStateMapOf<Int, String>() }

    // Default to first payment method covering the full total
    LaunchedEffect(paymentMethods) {
        if (paymentMethods.isNotEmpty() && amountInputs.isEmpty()) {
            amountInputs[paymentMethods.first().id] = "%.2f".format(total)
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Payment — ${"%.2f".format(total)}", fontWeight = FontWeight.SemiBold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Enter the amount for each payment method.", color = OperixTextSecondary, fontSize = 14.sp)
                paymentMethods.forEach { method ->
                    OutlinedTextField(
                        value = amountInputs[method.id] ?: "",
                        onValueChange = { amountInputs[method.id] = it },
                        label = { Text(method.displayName()) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }
                if (error != null) {
                    Text(error, color = OperixError, fontSize = 13.sp)
                }
                val collected = amountInputs.values.sumOf { it.toDoubleOrNull() ?: 0.0 }
                val remaining = total - collected
                if (remaining > 0.01) {
                    Text(
                        "Remaining: ${"%.2f".format(remaining)}",
                        color = OperixError,
                        fontWeight = FontWeight.Medium,
                        fontSize = 13.sp,
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val payments = amountInputs
                        .filter { (_, v) -> (v.toDoubleOrNull() ?: 0.0) > 0.0 }
                        .map { (id, v) -> CreatePosOrderPaymentRequest(id, v.toDouble()) }
                    onConfirm(payments)
                },
            ) {
                Text("Confirm Payment")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}
