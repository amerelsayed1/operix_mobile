package me.amermahsoub.bfm.features.pos.scanner

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.SecondaryButton

@Composable
actual fun CameraBarcodeScannerView(
    onBarcodeScanned: (String) -> Unit,
    onClose: () -> Unit,
) {
    val strings = appStrings()
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            strings.scannerNotAvailable,
            style = MaterialTheme.typography.titleMedium,
        )
        Spacer(Modifier.height(16.dp))
        SecondaryButton(text = strings.close, onClick = onClose)
    }
}
