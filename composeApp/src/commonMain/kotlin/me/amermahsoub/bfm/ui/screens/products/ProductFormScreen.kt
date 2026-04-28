package me.amermahsoub.bfm.ui.screens.products

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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
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
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.ProductCategory
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Unit as ProductUnit
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.viewmodel.products.ProductViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductFormScreen(
    productId: Int? = null,
    onSaved: () -> Unit,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ProductViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val categories by viewModel.categories.collectAsState()
    val units by viewModel.units.collectAsState()
    val productDetail by viewModel.productDetail.collectAsState()

    val scope = rememberCoroutineScope()

    // Form fields
    var name by remember { mutableStateOf("") }
    var sku by remember { mutableStateOf("") }
    var barcode by remember { mutableStateOf("") }
    var costPrice by remember { mutableStateOf("") }
    var sellingPrice by remember { mutableStateOf("") }
    var minimumStockAlert by remember { mutableStateOf("0") }
    var isActive by remember { mutableStateOf(true) }
    var selectedCategory by remember { mutableStateOf<ProductCategory?>(null) }
    var selectedUnit by remember { mutableStateOf<ProductUnit?>(null) }

    var isSaving by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Category dropdown state
    var categoryExpanded by remember { mutableStateOf(false) }
    var unitExpanded by remember { mutableStateOf(false) }

    // Add category dialog
    var showAddCategoryDialog by remember { mutableStateOf(false) }
    var newCategoryNameEn by remember { mutableStateOf("") }
    var newCategoryNameAr by remember { mutableStateOf("") }

    // Add unit dialog
    var showAddUnitDialog by remember { mutableStateOf(false) }
    var newUnitNameEn by remember { mutableStateOf("") }
    var newUnitNameAr by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        viewModel.loadCategories()
        viewModel.loadUnits()
        if (productId != null) {
            viewModel.loadProduct(productId)
        }
    }

    // Populate form when editing
    LaunchedEffect(productDetail) {
        if (productId != null && productDetail is Result.Success) {
            val p = (productDetail as Result.Success<Product>).data
            name = p.name
            sku = p.sku ?: ""
            barcode = p.barcode ?: ""
            costPrice = p.costPrice
            sellingPrice = p.sellingPrice
            minimumStockAlert = p.minimumStockAlert.toString()
            isActive = p.isActive
        }
    }

    // Set default selections once loaded
    LaunchedEffect(categories) {
        if (selectedCategory == null && productId != null && productDetail is Result.Success) {
            val p = (productDetail as Result.Success<Product>).data
            selectedCategory = categories.firstOrNull { it.id == p.productCategoryId }
        }
    }

    LaunchedEffect(units) {
        if (selectedUnit == null && productId != null && productDetail is Result.Success) {
            val p = (productDetail as Result.Success<Product>).data
            selectedUnit = units.firstOrNull { it.id == p.unitId }
        }
    }

    // Add Category Dialog
    if (showAddCategoryDialog) {
        AlertDialog(
            onDismissRequest = { showAddCategoryDialog = false },
            title = { Text("Add Category") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = newCategoryNameEn,
                        onValueChange = { newCategoryNameEn = it },
                        label = { Text("Name (English)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = newCategoryNameAr,
                        onValueChange = { newCategoryNameAr = it },
                        label = { Text("Name (Arabic) — optional") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (newCategoryNameEn.isNotBlank()) {
                        scope.launch {
                            val result = viewModel.createCategory(newCategoryNameEn, newCategoryNameAr.ifBlank { null })
                            if (result is Result.Success) {
                                selectedCategory = result.data
                                showAddCategoryDialog = false
                                newCategoryNameEn = ""
                                newCategoryNameAr = ""
                            }
                        }
                    }
                }) { Text("Add") }
            },
            dismissButton = {
                TextButton(onClick = { showAddCategoryDialog = false }) { Text("Cancel") }
            },
        )
    }

    // Add Unit Dialog
    if (showAddUnitDialog) {
        AlertDialog(
            onDismissRequest = { showAddUnitDialog = false },
            title = { Text("Add Unit") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = newUnitNameEn,
                        onValueChange = { newUnitNameEn = it },
                        label = { Text("Name (English)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = newUnitNameAr,
                        onValueChange = { newUnitNameAr = it },
                        label = { Text("Name (Arabic) — optional") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (newUnitNameEn.isNotBlank()) {
                        scope.launch {
                            val result = viewModel.createUnit(newUnitNameEn, newUnitNameAr.ifBlank { null })
                            if (result is Result.Success) {
                                selectedUnit = result.data
                                showAddUnitDialog = false
                                newUnitNameEn = ""
                                newUnitNameAr = ""
                            }
                        }
                    }
                }) { Text("Add") }
            },
            dismissButton = {
                TextButton(onClick = { showAddUnitDialog = false }) { Text("Cancel") }
            },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (productId == null) "New Product" else "Edit Product", fontWeight = FontWeight.Bold) },
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
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Name
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Product Name *") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
                isError = name.isBlank() && errorMessage != null,
            )

            // SKU
            OutlinedTextField(
                value = sku,
                onValueChange = { sku = it },
                label = { Text("SKU") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            // Category dropdown
            Column {
                ExposedDropdownMenuBox(
                    expanded = categoryExpanded,
                    onExpandedChange = { categoryExpanded = !categoryExpanded },
                ) {
                    OutlinedTextField(
                        value = selectedCategory?.displayName() ?: "",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Category *") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        shape = RoundedCornerShape(10.dp),
                    )
                    ExposedDropdownMenu(
                        expanded = categoryExpanded,
                        onDismissRequest = { categoryExpanded = false },
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
                        DropdownMenuItem(
                            text = { Text("+ Add New Category", color = OperixPrimary, fontWeight = FontWeight.Medium) },
                            onClick = {
                                categoryExpanded = false
                                showAddCategoryDialog = true
                            },
                        )
                    }
                }
            }

            // Unit dropdown
            Column {
                ExposedDropdownMenuBox(
                    expanded = unitExpanded,
                    onExpandedChange = { unitExpanded = !unitExpanded },
                ) {
                    OutlinedTextField(
                        value = selectedUnit?.displayName() ?: "",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Unit *") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = unitExpanded) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        shape = RoundedCornerShape(10.dp),
                    )
                    ExposedDropdownMenu(
                        expanded = unitExpanded,
                        onDismissRequest = { unitExpanded = false },
                    ) {
                        units.forEach { unit ->
                            DropdownMenuItem(
                                text = { Text(unit.displayName()) },
                                onClick = {
                                    selectedUnit = unit
                                    unitExpanded = false
                                },
                            )
                        }
                        DropdownMenuItem(
                            text = { Text("+ Add New Unit", color = OperixPrimary, fontWeight = FontWeight.Medium) },
                            onClick = {
                                unitExpanded = false
                                showAddUnitDialog = true
                            },
                        )
                    }
                }
            }

            // Prices row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = costPrice,
                    onValueChange = { costPrice = it },
                    label = { Text("Cost Price") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(10.dp),
                )
                OutlinedTextField(
                    value = sellingPrice,
                    onValueChange = { sellingPrice = it },
                    label = { Text("Selling Price *") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    shape = RoundedCornerShape(10.dp),
                )
            }

            // Barcode
            OutlinedTextField(
                value = barcode,
                onValueChange = { barcode = it },
                label = { Text("Barcode") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            // Minimum stock alert
            OutlinedTextField(
                value = minimumStockAlert,
                onValueChange = { minimumStockAlert = it },
                label = { Text("Minimum Stock Alert") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                shape = RoundedCornerShape(10.dp),
            )

            // Active toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column {
                    Text("Active", fontWeight = FontWeight.Medium)
                    Text("Product is visible and available for sale", color = me.amermahsoub.bfm.ui.theme.OperixTextSecondary, fontSize = 12.sp)
                }
                Switch(checked = isActive, onCheckedChange = { isActive = it })
            }

            // Error
            if (errorMessage != null) {
                Text(
                    text = errorMessage!!,
                    color = OperixError,
                    style = MaterialTheme.typography.bodySmall,
                )
            }

            Spacer(Modifier.height(4.dp))

            // Save button
            Button(
                onClick = {
                    val nameVal = name.trim()
                    val catId = selectedCategory?.id
                    val unitId = selectedUnit?.id
                    val selling = sellingPrice.toDoubleOrNull()

                    when {
                        nameVal.isBlank() -> errorMessage = "Product name is required."
                        catId == null -> errorMessage = "Please select a category."
                        unitId == null -> errorMessage = "Please select a unit."
                        selling == null || selling <= 0 -> errorMessage = "Enter a valid selling price."
                        else -> {
                            errorMessage = null
                            isSaving = true
                            scope.launch {
                                val result = if (productId == null) {
                                    viewModel.createProduct(
                                        name = nameVal,
                                        sku = sku.trim(),
                                        categoryId = catId,
                                        unitId = unitId,
                                        costPrice = costPrice.toDoubleOrNull() ?: 0.0,
                                        sellingPrice = selling,
                                        barcode = barcode.ifBlank { null },
                                        isActive = isActive,
                                        minimumStockAlert = minimumStockAlert.toIntOrNull() ?: 0,
                                    )
                                } else {
                                    viewModel.updateProduct(
                                        productId,
                                        buildMap {
                                            put("name", nameVal)
                                            put("sku", sku.trim())
                                            put("product_category_id", catId)
                                            put("unit_id", unitId)
                                            put("cost_price", costPrice.toDoubleOrNull() ?: 0.0)
                                            put("selling_price", selling)
                                            put("barcode", barcode.ifBlank { null })
                                            put("is_active", isActive)
                                            put("minimum_stock_alert", minimumStockAlert.toIntOrNull() ?: 0)
                                        },
                                    )
                                }
                                isSaving = false
                                when (result) {
                                    is Result.Success -> onSaved()
                                    is Result.Error -> errorMessage = result.message
                                    else -> {}
                                }
                            }
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
                    CircularProgressIndicator(modifier = Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
                } else {
                    Text(if (productId == null) "Create Product" else "Save Changes", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}
