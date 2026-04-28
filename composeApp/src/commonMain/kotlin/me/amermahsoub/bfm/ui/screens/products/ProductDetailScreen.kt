package me.amermahsoub.bfm.ui.screens.products

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.Edit2
import compose.icons.feathericons.Package
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.ProductUnit
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.products.ProductViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductDetailScreen(
    productId: Int,
    onNavigateToEdit: (Int) -> Unit,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ProductViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val productDetailState by viewModel.productDetail.collectAsState()

    LaunchedEffect(productId) {
        viewModel.loadProduct(productId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Product Detail", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(onClick = { onNavigateToEdit(productId) }) {
                        Icon(FeatherIcons.Edit2, contentDescription = "Edit", modifier = Modifier.size(16.dp))
                        Text("  Edit")
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
        when (val state = productDetailState) {
            is Result.Loading -> LoadingScreen()
            is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadProduct(productId) })
            is Result.Success -> {
                val product = state.data
                Column(
                    modifier = Modifier
                        .padding(padding)
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState()),
                ) {
                    // Image placeholder / product header
                    ProductImageHeader(product)

                    Spacer(Modifier.height(8.dp))

                    // Main info card
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(
                                    product.name,
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.weight(1f),
                                )
                                StatusBadge(if (product.isActive) "active" else "inactive")
                            }

                            if (!product.sku.isNullOrBlank()) {
                                Spacer(Modifier.height(4.dp))
                                Text("SKU: ${product.sku}", color = OperixTextSecondary, fontSize = 13.sp)
                            }

                            if (!product.barcode.isNullOrBlank()) {
                                Spacer(Modifier.height(2.dp))
                                Text("Barcode: ${product.barcode}", color = OperixTextSecondary, fontSize = 13.sp)
                            }

                            Spacer(Modifier.height(12.dp))
                            Divider()
                            Spacer(Modifier.height(12.dp))

                            InfoRow("Category", product.category?.displayName() ?: "—")
                            Spacer(Modifier.height(8.dp))
                            InfoRow("Unit", product.unit?.displayName() ?: "—")
                            Spacer(Modifier.height(12.dp))
                            Divider()
                            Spacer(Modifier.height(12.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(24.dp),
                            ) {
                                Column {
                                    Text("Cost Price", color = OperixTextSecondary, fontSize = 12.sp)
                                    Spacer(Modifier.height(4.dp))
                                    AmountText(amount = product.costPrice, positive = true)
                                }
                                Column {
                                    Text("Selling Price", color = OperixTextSecondary, fontSize = 12.sp)
                                    Spacer(Modifier.height(4.dp))
                                    AmountText(amount = product.sellingPrice, positive = true, large = true)
                                }
                            }
                        }
                    }

                    Spacer(Modifier.height(12.dp))

                    // Stock section
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        SectionHeader("Stock")
                        Column(modifier = Modifier.padding(horizontal = 16.dp).padding(bottom = 16.dp)) {
                            InfoRow("Minimum Stock Alert", product.minimumStockAlert.toString())
                            if (product.hasVariants) {
                                Spacer(Modifier.height(4.dp))
                                Text("This product has variants", color = OperixTextSecondary, fontSize = 13.sp)
                            }
                        }
                    }

                    // Units section
                    if (product.units.isNotEmpty()) {
                        Spacer(Modifier.height(12.dp))
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            colors = CardDefaults.cardColors(containerColor = Color.White),
                            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                            shape = RoundedCornerShape(12.dp),
                        ) {
                            SectionHeader("Units")
                            Column(modifier = Modifier.padding(bottom = 8.dp)) {
                                product.units.forEachIndexed { index, pu ->
                                    ProductUnitRow(pu)
                                    if (index < product.units.lastIndex) Divider()
                                }
                            }
                        }
                    }

                    Spacer(Modifier.height(24.dp))
                }
            }
        }
    }
}

@Composable
private fun ProductImageHeader(product: Product) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp)
            .background(MaterialTheme.colorScheme.primaryContainer),
        contentAlignment = Alignment.Center,
    ) {
        if (product.imageUrl != null) {
            // In a real implementation, use AsyncImage from coil; placeholder here
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    FeatherIcons.Package,
                    contentDescription = null,
                    tint = OperixPrimary,
                    modifier = Modifier.size(48.dp),
                )
            }
        } else {
            Icon(
                FeatherIcons.Package,
                contentDescription = null,
                tint = OperixPrimary,
                modifier = Modifier.size(64.dp),
            )
        }
    }
}

@Composable
private fun ProductUnitRow(pu: ProductUnit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(pu.unit?.displayName() ?: "Unit #${pu.unitId}", fontWeight = FontWeight.Medium)
            if (!pu.barcode.isNullOrBlank()) {
                Text("Barcode: ${pu.barcode}", color = OperixTextSecondary, fontSize = 12.sp)
            }
            Text("Factor: ${pu.conversionFactor}", color = OperixTextSecondary, fontSize = 12.sp)
        }
        if (pu.isDefault) StatusBadge("active")
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, color = OperixTextSecondary, fontSize = 13.sp)
        Text(value, fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}
