package me.amermahsoub.bfm

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import me.amermahsoub.bfm.shared.data.tenant.TenantConfig

@Immutable
data class TenantColors(
    val primary: Color,
    val background: Color,
    val onPrimary: Color,
)

private val DefaultTenantColors = TenantColors(
    primary = Color(0xFF5B7BE8),
    background = Color(0xFFF5F7FB),
    onPrimary = Color.White,
)

val LocalTenantColors = staticCompositionLocalOf { DefaultTenantColors }

@Composable
fun TenantTheme(
    tenantConfig: TenantConfig?,
    content: @Composable () -> Unit,
) {
    val colors = tenantColorsFromConfig(tenantConfig)
    val base = MaterialTheme.colorScheme
    val colorScheme = base.copy(
        primary = colors.primary,
        onPrimary = colors.onPrimary,
        background = colors.background,
        surface = colors.background,
    )

    MaterialTheme(colorScheme = colorScheme) {
        CompositionLocalProvider(LocalTenantColors provides colors) {
            content()
        }
    }
}

@Composable
@ReadOnlyComposable
fun tenantColors(): TenantColors = LocalTenantColors.current

private fun tenantColorsFromConfig(config: TenantConfig?): TenantColors {
    val primary = config?.primaryColorHex.parseColorOrNull() ?: DefaultTenantColors.primary
    val background = config?.backgroundColorHex.parseColorOrNull() ?: DefaultTenantColors.background
    val onPrimary = if (primary.luminance() < 0.5f) Color.White else Color.Black
    return TenantColors(primary = primary, background = background, onPrimary = onPrimary)
}

private fun String?.parseColorOrNull(): Color? {
    val value = this?.trim().orEmpty()
    if (!value.startsWith("#")) return null
    val hex = value.drop(1)
    val packed = when (hex.length) {
        6 -> (hex.toLongOrNull(16)?.let { 0xFF000000 or it } ?: return null)
        8 -> hex.toLongOrNull(16) ?: return null
        else -> return null
    }
    return Color(packed)
}

