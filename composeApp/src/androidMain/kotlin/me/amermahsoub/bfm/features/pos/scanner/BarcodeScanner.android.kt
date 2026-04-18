package me.amermahsoub.bfm.features.pos.scanner

import android.Manifest
import android.content.pm.PackageManager
import android.util.Size
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.OptIn
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.SecondaryButton
import java.util.concurrent.Executors

@Composable
actual fun CameraBarcodeScannerView(
    onBarcodeScanned: (String) -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    val strings = appStrings()
    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted -> hasPermission = granted }

    LaunchedEffect(Unit) {
        if (!hasPermission) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    if (hasPermission) {
        CameraPreviewWithScanner(onBarcodeScanned = onBarcodeScanned, onClose = onClose)
    } else {
        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                strings.cameraPermissionRequired,
                style = MaterialTheme.typography.titleMedium,
            )
            Spacer(Modifier.height(16.dp))
            PrimaryButton(
                text = strings.grantPermission,
                onClick = { permissionLauncher.launch(Manifest.permission.CAMERA) },
            )
            Spacer(Modifier.height(8.dp))
            SecondaryButton(text = strings.cancel, onClick = onClose)
        }
    }
}

@Composable
private fun CameraPreviewWithScanner(
    onBarcodeScanned: (String) -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val strings = appStrings()
    var scannedValue by remember { mutableStateOf<String?>(null) }
    val executor = remember { Executors.newSingleThreadExecutor() }

    DisposableEffect(Unit) {
        onDispose { executor.shutdown() }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        AndroidView(
            factory = { ctx ->
                val previewView = PreviewView(ctx)
                val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)

                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.surfaceProvider = previewView.surfaceProvider
                    }

                    val imageAnalysis = ImageAnalysis.Builder()
                        .setTargetResolution(Size(1280, 720))
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build()
                        .also { analysis ->
                            analysis.setAnalyzer(executor) { imageProxy ->
                                processImage(imageProxy) { barcode ->
                                    if (scannedValue == null) {
                                        scannedValue = barcode
                                        onBarcodeScanned(barcode)
                                    }
                                }
                            }
                        }

                    try {
                        cameraProvider.unbindAll()
                        cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            CameraSelector.DEFAULT_BACK_CAMERA,
                            preview,
                            imageAnalysis,
                        )
                    } catch (_: Exception) {
                    }
                }, ContextCompat.getMainExecutor(ctx))

                previewView
            },
            modifier = Modifier.fillMaxSize(),
        )

        // Scan overlay
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            Box(
                modifier = Modifier
                    .size(250.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .border(3.dp, Color.White.copy(alpha = 0.7f), RoundedCornerShape(16.dp)),
            )
        }

        // Bottom hint + close
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                strings.pointCameraAtBarcode,
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White,
            )
            Spacer(Modifier.height(16.dp))
            SecondaryButton(text = strings.close, onClick = onClose)
        }
    }
}

@OptIn(ExperimentalGetImage::class)
private fun processImage(imageProxy: ImageProxy, onBarcode: (String) -> Unit) {
    val mediaImage = imageProxy.image
    if (mediaImage == null) {
        imageProxy.close()
        return
    }

    val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
    val scanner = BarcodeScanning.getClient()

    scanner.process(inputImage)
        .addOnSuccessListener { barcodes ->
            for (barcode in barcodes) {
                val value = barcode.rawValue
                if (!value.isNullOrBlank()) {
                    onBarcode(value)
                    break
                }
            }
        }
        .addOnCompleteListener {
            imageProxy.close()
        }
}
