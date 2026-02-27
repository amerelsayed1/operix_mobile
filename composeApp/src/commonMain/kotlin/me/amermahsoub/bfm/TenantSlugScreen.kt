package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .widthIn(max = 420.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = "Select Your Organization",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
            Text(
                text = "Enter your organization's slug to continue",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )

            Text(
                text = "Organization Slug",
                style = MaterialTheme.typography.labelLarge,
            )
            OutlinedTextField(
                value = state.slugText,
                onValueChange = onSlugChange,
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("acme-corp") },
                prefix = { Text("http://localhost:5173/") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    autoCorrect = false,
                    keyboardType = KeyboardType.Text,
                ),
            )

            Text(
                text = "Example: acme-corp, tech-innovations, global-trading",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            Button(
                onClick = onContinue,
                enabled = trimmedSlug.isNotBlank() && !state.isSaving,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(if (state.isSaving) "Saving..." else "Continue")
            }

            if (state.slugText.isNotEmpty()) {
                Button(
                    onClick = onClear,
                    enabled = !state.isSaving,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Clear")
                }
            }

            if (state.errorMessage != null) {
                Text(state.errorMessage, color = MaterialTheme.colorScheme.error)
            }
        }
    }
}
