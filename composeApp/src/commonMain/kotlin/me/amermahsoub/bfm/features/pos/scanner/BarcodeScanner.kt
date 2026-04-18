package me.amermahsoub.bfm.features.pos.scanner

import androidx.compose.runtime.Composable

@Composable
expect fun CameraBarcodeScannerView(
    onBarcodeScanned: (String) -> Unit,
    onClose: () -> Unit,
)
