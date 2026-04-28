package me.amermahsoub.bfm.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val OperixPrimary = Color(0xFF1D4ED8)
val OperixPrimaryLight = Color(0xFF3B82F6)
val OperixSurface = Color(0xFFF8FAFC)
val OperixError = Color(0xFFEF4444)
val OperixSuccess = Color(0xFF22C55E)
val OperixWarning = Color(0xFFF59E0B)
val OperixTextPrimary = Color(0xFF0F172A)
val OperixTextSecondary = Color(0xFF64748B)

private val LightColors = lightColorScheme(
    primary = OperixPrimary,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDBEAFE),
    onPrimaryContainer = OperixPrimary,
    secondary = Color(0xFF0EA5E9),
    onSecondary = Color.White,
    background = OperixSurface,
    surface = Color.White,
    onBackground = OperixTextPrimary,
    onSurface = OperixTextPrimary,
    error = OperixError,
    onError = Color.White,
    outline = Color(0xFFE2E8F0),
)

@Composable
fun OperixTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        content = content,
    )
}
