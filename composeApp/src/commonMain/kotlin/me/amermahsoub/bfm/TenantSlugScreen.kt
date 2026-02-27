package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
fun TenantSlugScreen(
    state: TenantSlugUiState,
    onSlugChange: (String) -> Unit,
    onContinue: () -> Unit,
    onClear: () -> Unit,
) {
    val trimmedSlug = state.slugText.trim()

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Enter Tenant Slug", style = MaterialTheme.typography.headlineSmall)
        OutlinedTextField(
            value = state.slugText,
            onValueChange = onSlugChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("tech-innovations") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                autoCorrect = false,
                keyboardType = KeyboardType.Text,
            ),
            colors = TextFieldDefaults.colors(),
        )

        if (state.errorMessage != null) {
            Text(state.errorMessage, color = MaterialTheme.colorScheme.error)
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(
                onClick = onContinue,
                enabled = trimmedSlug.isNotBlank() && !state.isSaving,
            ) {
                Text(if (state.isSaving) "Saving..." else "Continue")
            }
            Button(onClick = onClear, enabled = state.slugText.isNotEmpty() && !state.isSaving) {
                Text("Clear")
            }
        }
    }
}
