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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.runtime.mutableStateListOf
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
import compose.icons.feathericons.Plus
import compose.icons.feathericons.Trash2
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.CreateInvoiceItemRequest
import me.amermahsoub.bfm.shared.data.models.CreatePurchaseInvoiceRequest
import me.amermahsoub.bfm.shared.data.models.Inventory
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.invoices.PurchaseInvoiceViewModel
import org.koin.core.context.GlobalContext

private data class PurchaseLineItem(
    val product: Product? = null,
    val quantity: String = "1",
    val unitPrice: String = "",
    val discount: String = "0",
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PurchaseInvoiceFormScreen(
    onSaved: (Int) -> Unit,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        PurchaseInvoiceViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val suppliers by viewModel.suppliers.collectAsState()
    val products by viewModel.products.collectAsState()
    val inventories by viewModel.inventories.collectAsState()
    val scope = rememberCoroutineScope()

    var selectedSupplier by remember { mutableStateOf<Supplier?>(null) }
    var invoiceDate by remember { mutableStateOf("") }
    var dueDate by remember { mutableStateOf("") }
    var selectedInventory by remember { mutableStateOf<Inventory?>(null) }
    var supplierInvoiceNumber by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    val lineItems = remember { mutableStateListOf(PurchaseLineItem()) }
    var isSaving by remember { mutableStateOf(false) }
    var formError by remember { mutableStateOf<String?>(null) }

    var supplierDropdownExpanded by remember { mutableStateOf(false) }
    var supplierSearch by remember { mutableStateOf("") }
    var inventoryDropdownExpanded by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadFormData()
    }

    // Derived totals
    val subtotal = lineItems.sumOf { item ->
        val qty = item.quantity.toDoubleOrNull() ?: 0.0
        val price = item.unitPrice.toDoubleOrNull() ?: 0.0
        val disc = item.discount.toDoubleOrNull() ?: 0.0
        qty * price - disc
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Purchase Invoice", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        containerColor = OperixSurface,
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
            ) {
                if (formError != null) {
                    Text(
                        text = formError!!,
                        color = OperixError,
                        fontSize = 13.sp,
                        modifier = Modifier.padding(bottom = 8.dp),
                    )
                }
                Button(
                    onClick = {
                        val supplier = selectedSupplier
                        val inventory = selectedInventory
                        if (supplier == null) {
                            formError = "Please select a supplier."
                            return@Button
                        }
                        if (inventory == null) {
                            formError = "Please select an inventory."
                            return@Button
                        }
                        if (invoiceDate.isBlank()) {
                            formError = "Please enter an invoice date."
                            return@Button
                        }
                        val itemRequests = lineItems.mapNotNull { item ->
                            val product = item.product ?: return@mapNotNull null
                            val qty = item.quantity.toDoubleOrNull() ?: return@mapNotNull null
                            val price = item.unitPrice.toDoubleOrNull() ?: return@mapNotNull null
                            CreateInvoiceItemRequest(
                                productId = product.id,
                                quantity = qty,
                                unitPrice = price,
                                discount = item.discount.toDoubleOrNull() ?: 0.0,
                            )
                        }
                        if (itemRequests.isEmpty()) {
                            formError = "Please add at least one item."
                            return@Button
                        }
                        formError = null
                        isSaving = true
                        scope.launch {
                            val result = viewModel.createInvoice(
                                CreatePurchaseInvoiceRequest(
                                    supplierId = supplier.id,
                                    invoiceDate = invoiceDate,
                                    dueDate = dueDate.ifBlank { null },
                                    inventoryId = inventory.id,
                                    supplierInvoiceNumber = supplierInvoiceNumber.ifBlank { null },
                                    items = itemRequests,
                                    notes = notes.ifBlank { null },
                                ),
                            )
                            isSaving = false
                            when (result) {
                                is Result.Success -> onSaved(result.data.id)
                                is Result.Error -> formError = result.message
                                else -> {}
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    enabled = !isSaving,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
                ) {
                    if (isSaving) {
                        Text("Saving…")
                    } else {
                        Text("Save as Draft", fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    }
                }
            }
        },
    ) { innerPadding ->
        if (suppliers.isEmpty() && inventories.isEmpty()) {
            LoadingScreen("Loading form data…")
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(bottom = 8.dp),
            ) {
                // Supplier picker
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
                            ExposedDropdownMenuBox(
                                expanded = supplierDropdownExpanded,
                                onExpandedChange = { supplierDropdownExpanded = it },
                            ) {
                                OutlinedTextField(
                                    value = if (selectedSupplier != null) selectedSupplier!!.companyName else supplierSearch,
                                    onValueChange = { value ->
                                        supplierSearch = value
                                        selectedSupplier = null
                                        supplierDropdownExpanded = true
                                    },
                                    label = { Text("Search supplier") },
                                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(supplierDropdownExpanded) },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .menuAnchor(MenuAnchorType.PrimaryEditable),
                                    shape = RoundedCornerShape(10.dp),
                                    singleLine = true,
                                )
                                val filteredSuppliers = suppliers.filter {
                                    supplierSearch.isBlank() ||
                                        it.companyName.contains(supplierSearch, ignoreCase = true)
                                }
                                if (filteredSuppliers.isNotEmpty()) {
                                    ExposedDropdownMenu(
                                        expanded = supplierDropdownExpanded,
                                        onDismissRequest = { supplierDropdownExpanded = false },
                                    ) {
                                        filteredSuppliers.forEach { supplier ->
                                            DropdownMenuItem(
                                                text = { Text(supplier.companyName) },
                                                onClick = {
                                                    selectedSupplier = supplier
                                                    supplierSearch = supplier.companyName
                                                    supplierDropdownExpanded = false
                                                },
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Dates, Inventory & Supplier Invoice Number
                item {
                    SectionHeader(title = "Details")
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(1.dp),
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            OutlinedTextField(
                                value = invoiceDate,
                                onValueChange = { invoiceDate = it },
                                label = { Text("Invoice Date (YYYY-MM-DD)") },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(10.dp),
                                singleLine = true,
                            )
                            OutlinedTextField(
                                value = dueDate,
                                onValueChange = { dueDate = it },
                                label = { Text("Due Date (optional)") },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(10.dp),
                                singleLine = true,
                            )
                            OutlinedTextField(
                                value = supplierInvoiceNumber,
                                onValueChange = { supplierInvoiceNumber = it },
                                label = { Text("Supplier Invoice Number (optional)") },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(10.dp),
                                singleLine = true,
                            )

                            // Inventory selector
                            ExposedDropdownMenuBox(
                                expanded = inventoryDropdownExpanded,
                                onExpandedChange = { inventoryDropdownExpanded = it },
                            ) {
                                OutlinedTextField(
                                    value = selectedInventory?.name ?: "Select inventory",
                                    onValueChange = {},
                                    readOnly = true,
                                    label = { Text("Inventory") },
                                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(inventoryDropdownExpanded) },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .menuAnchor(MenuAnchorType.PrimaryNotEditable),
                                    shape = RoundedCornerShape(10.dp),
                                )
                                ExposedDropdownMenu(
                                    expanded = inventoryDropdownExpanded,
                                    onDismissRequest = { inventoryDropdownExpanded = false },
                                ) {
                                    inventories.forEach { inv ->
                                        DropdownMenuItem(
                                            text = { Text(inv.name) },
                                            onClick = {
                                                selectedInventory = inv
                                                inventoryDropdownExpanded = false
                                            },
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // Line items
                item { SectionHeader(title = "Items") }

                itemsIndexed(lineItems) { index, lineItem ->
                    PurchaseLineItemCard(
                        item = lineItem,
                        products = products,
                        onUpdate = { updated -> lineItems[index] = updated },
                        onRemove = if (lineItems.size > 1) ({ lineItems.removeAt(index) }) else null,
                    )
                }

                item {
                    TextButton(
                        onClick = { lineItems.add(PurchaseLineItem()) },
                        modifier = Modifier.padding(horizontal = 16.dp),
                    ) {
                        Icon(FeatherIcons.Plus, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Add Item")
                    }
                }

                // Summary
                item {
                    SectionHeader(title = "Summary")
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(1.dp),
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Divider()
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text("Total Cost", fontWeight = FontWeight.Bold)
                                Text(
                                    "%.2f".format(subtotal),
                                    fontWeight = FontWeight.Bold,
                                    color = OperixPrimary,
                                    fontSize = 16.sp,
                                )
                            }
                        }
                    }
                }

                // Notes
                item {
                    SectionHeader(title = "Notes")
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(1.dp),
                    ) {
                        OutlinedTextField(
                            value = notes,
                            onValueChange = { notes = it },
                            label = { Text("Notes (optional)") },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            shape = RoundedCornerShape(10.dp),
                            maxLines = 4,
                        )
                    }
                    Spacer(Modifier.height(16.dp))
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PurchaseLineItemCard(
    item: PurchaseLineItem,
    products: List<Product>,
    onUpdate: (PurchaseLineItem) -> Unit,
    onRemove: (() -> Unit)?,
) {
    var productDropdownExpanded by remember { mutableStateOf(false) }
    var productSearch by remember { mutableStateOf(item.product?.name ?: "") }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(1.dp),
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Line Item", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                if (onRemove != null) {
                    IconButton(onClick = onRemove, modifier = Modifier.size(32.dp)) {
                        Icon(
                            FeatherIcons.Trash2,
                            contentDescription = "Remove",
                            tint = OperixError,
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
            }

            // Product picker
            ExposedDropdownMenuBox(
                expanded = productDropdownExpanded,
                onExpandedChange = { productDropdownExpanded = it },
            ) {
                OutlinedTextField(
                    value = if (item.product != null) item.product.name else productSearch,
                    onValueChange = { value ->
                        productSearch = value
                        if (item.product != null) onUpdate(item.copy(product = null, unitPrice = ""))
                        productDropdownExpanded = true
                    },
                    label = { Text("Product") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(productDropdownExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(MenuAnchorType.PrimaryEditable),
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                )
                val filtered = products.filter {
                    productSearch.isBlank() || it.name.contains(productSearch, ignoreCase = true)
                }
                if (filtered.isNotEmpty()) {
                    ExposedDropdownMenu(
                        expanded = productDropdownExpanded,
                        onDismissRequest = { productDropdownExpanded = false },
                    ) {
                        filtered.forEach { product ->
                            DropdownMenuItem(
                                text = {
                                    Column {
                                        Text(product.name)
                                        Text(
                                            "Cost: ${product.costPrice}",
                                            fontSize = 11.sp,
                                            color = OperixTextSecondary,
                                        )
                                    }
                                },
                                onClick = {
                                    productSearch = product.name
                                    // Use costPrice as default unit price for purchases
                                    onUpdate(item.copy(product = product, unitPrice = product.costPrice))
                                    productDropdownExpanded = false
                                },
                            )
                        }
                    }
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = item.quantity,
                    onValueChange = { onUpdate(item.copy(quantity = it)) },
                    label = { Text("Qty") },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = item.unitPrice,
                    onValueChange = { onUpdate(item.copy(unitPrice = it)) },
                    label = { Text("Cost Price") },
                    modifier = Modifier.weight(1.5f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = item.discount,
                    onValueChange = { onUpdate(item.copy(discount = it)) },
                    label = { Text("Disc.") },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                )
            }

            val lineTotal = (item.quantity.toDoubleOrNull() ?: 0.0) *
                (item.unitPrice.toDoubleOrNull() ?: 0.0) -
                (item.discount.toDoubleOrNull() ?: 0.0)
            Text(
                text = "Line Total: %.2f".format(lineTotal),
                fontSize = 12.sp,
                color = OperixTextSecondary,
                fontWeight = FontWeight.Medium,
            )
        }
    }
}
