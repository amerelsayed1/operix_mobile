package me.amermahsoub.bfm.app.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Derives a Material3 [ColorScheme] from the tenant's theme primary color.
 * Keeps the app aligned with SRS §10.9 (tenant branding via `ColorScheme.fromSeed`).
 */
private val DefaultPrimary = Color(0xFF4F46E5)

val LocalTenantPrimary = staticCompositionLocalOf { DefaultPrimary }

@Composable
fun TenantTheme(
    primaryColorHex: String? = null,
    darkTheme: Boolean = false,
    content: @Composable () -> Unit,
) {
    val primary = parseHexColor(primaryColorHex) ?: DefaultPrimary
    val scheme = buildColorScheme(primary, darkTheme)
    CompositionLocalProvider(LocalTenantPrimary provides primary) {
        MaterialTheme(colorScheme = scheme, typography = appTypography(), content = content)
    }
}

private fun buildColorScheme(primary: Color, dark: Boolean): ColorScheme {
    val onPrimary = contrastingOn(primary)
    return if (dark) {
        darkColorScheme(
            primary = primary,
            onPrimary = onPrimary,
            primaryContainer = primary.copy(alpha = 0.25f),
            onPrimaryContainer = onPrimary,
        )
    } else {
        lightColorScheme(
            primary = primary,
            onPrimary = onPrimary,
            primaryContainer = lighten(primary, 0.85f),
            onPrimaryContainer = darken(primary, 0.3f),
        )
    }
}

private fun parseHexColor(raw: String?): Color? {
    if (raw.isNullOrBlank()) return null
    val hex = raw.trim().removePrefix("#")
    val normalized = when (hex.length) {
        6 -> "FF$hex"
        8 -> hex
        else -> return null
    }
    val value = normalized.toLongOrNull(16) ?: return null
    return Color(value.toInt())
}

private fun lighten(c: Color, factor: Float): Color = Color(
    red = c.red + (1f - c.red) * factor,
    green = c.green + (1f - c.green) * factor,
    blue = c.blue + (1f - c.blue) * factor,
    alpha = c.alpha,
)

private fun darken(c: Color, factor: Float): Color = Color(
    red = c.red * (1f - factor),
    green = c.green * (1f - factor),
    blue = c.blue * (1f - factor),
    alpha = c.alpha,
)

private fun contrastingOn(c: Color): Color {
    val luminance = 0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue
    return if (luminance > 0.6) Color(0xFF111111) else Color.White
}
