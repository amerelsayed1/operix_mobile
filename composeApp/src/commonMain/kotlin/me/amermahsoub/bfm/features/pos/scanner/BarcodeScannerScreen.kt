package me.amermahsoub.bfm.features.pos.scanner

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

@Composable
fun BarcodeScannerScreen(
    onScanned: (String) -> Unit,
    onClose: () -> Unit,
) {
    Box(
        modifier = Modifier.fillMaxSize().background(Color.Black),
    ) {
        CameraBarcodeScannerView(
            onBarcodeScanned = onScanned,
            onClose = onClose,
        )
    }
}
