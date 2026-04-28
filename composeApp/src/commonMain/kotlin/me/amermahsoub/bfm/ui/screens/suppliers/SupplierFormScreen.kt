package me.amermahsoub.bfm.ui.screens.suppliers

import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
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
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.viewmodel.suppliers.SupplierViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SupplierFormScreen(
    supplierId: Int? = null,
    onSaved: () -> Unit,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        SupplierViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val supplierDetail by viewModel.supplierDetail.collectAsState()
    val scope = rememberCoroutineScope()

    var companyName by remember { mutableStateOf("") }
    var contactName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var taxNumber by remember { mutableStateOf("") }
    var paymentTerms by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    var isSaving by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(supplierId) {
        if (supplierId != null) viewModel.loadSupplier(supplierId)
    }

    LaunchedEffect(supplierDetail) {
        if (supplierId != null && supplierDetail is Result.Success) {
            val s = (supplierDetail as Result.Success<Supplier>).data
            companyName = s.companyName
            contactName = s.contactName ?: ""
            phone = s.phone ?: ""
            email = s.email ?: ""
            address = s.address ?: ""
            taxNumber = s.taxNumber ?: ""
            paymentTerms = s.paymentTerms?.toString() ?: ""
            notes = s.notes ?: ""
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (supplierId == null) "New Supplier" else "Edit Supplier", fontWeight = FontWeight.Bold) },
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
            OutlinedTextField(
                value = companyName,
                onValueChange = { companyName = it },
                label = { Text("Company Name *") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
                isError = companyName.isBlank() && errorMessage != null,
            )

            OutlinedTextField(
                value = contactName,
                onValueChange = { contactName = it },
                label = { Text("Contact Name") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it },
                label = { Text("Phone") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                shape = RoundedCornerShape(10.dp),
            )

            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                shape = RoundedCornerShape(10.dp),
            )

            OutlinedTextField(
                value = address,
                onValueChange = { address = it },
                label = { Text("Address") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4,
                shape = RoundedCornerShape(10.dp),
            )

            OutlinedTextField(
                value = taxNumber,
                onValueChange = { taxNumber = it },
                label = { Text("Tax Number") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )

            OutlinedTextField(
                value = paymentTerms,
                onValueChange = { paymentTerms = it },
                label = { Text("Payment Terms (days)") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                shape = RoundedCornerShape(10.dp),
            )

            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it },
                label = { Text("Notes") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 4,
                shape = RoundedCornerShape(10.dp),
            )

            if (errorMessage != null) {
                Text(text = errorMessage!!, color = OperixError, style = MaterialTheme.typography.bodySmall)
            }

            Spacer(Modifier.height(4.dp))

            Button(
                onClick = {
                    val nameVal = companyName.trim()
                    if (nameVal.isBlank()) {
                        errorMessage = "Company name is required."
                        return@Button
                    }
                    errorMessage = null
                    isSaving = true
                    scope.launch {
                        val result = if (supplierId == null) {
                            viewModel.createSupplier(
                                companyName = nameVal,
                                contactName = contactName.ifBlank { null },
                                phone = phone.ifBlank { null },
                                email = email.ifBlank { null },
                                address = address.ifBlank { null },
                                taxNumber = taxNumber.ifBlank { null },
                                paymentTerms = paymentTerms.toIntOrNull(),
                                notes = notes.ifBlank { null },
                            )
                        } else {
                            viewModel.updateSupplier(
                                supplierId,
                                buildMap {
                                    put("company_name", nameVal)
                                    put("contact_name", contactName.ifBlank { null })
                                    put("phone", phone.ifBlank { null })
                                    put("email", email.ifBlank { null })
                                    put("address", address.ifBlank { null })
                                    put("tax_number", taxNumber.ifBlank { null })
                                    put("payment_terms", paymentTerms.toIntOrNull())
                                    put("notes", notes.ifBlank { null })
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
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                enabled = !isSaving,
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
            ) {
                if (isSaving) {
                    CircularProgressIndicator(modifier = Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
                } else {
                    Text(if (supplierId == null) "Create Supplier" else "Save Changes", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}
