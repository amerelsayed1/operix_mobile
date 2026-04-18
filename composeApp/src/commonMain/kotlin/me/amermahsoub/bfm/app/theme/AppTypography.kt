package me.amermahsoub.bfm.app.theme

import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import me.amermahsoub.bfm.composeapp.resources.Res
import me.amermahsoub.bfm.composeapp.resources.cairo
import org.jetbrains.compose.resources.Font

/**
 * Cairo is a variable TTF that ships with Latin + Arabic glyphs and the
 * full weight axis. We register four logical weights against the same
 * resource — Compose / Skia picks the right wght axis at render time.
 */
@Composable
fun cairoFontFamily(): FontFamily = FontFamily(
    Font(Res.font.cairo, weight = FontWeight.Normal),
    Font(Res.font.cairo, weight = FontWeight.Medium),
    Font(Res.font.cairo, weight = FontWeight.SemiBold),
    Font(Res.font.cairo, weight = FontWeight.Bold),
)

/**
 * Builds a Material3 [Typography] that reuses the default sizes / line
 * heights but swaps every text style's font family to Cairo so Arabic
 * and Latin both render with the brand typeface.
 */
@Composable
fun appTypography(): Typography {
    val family = cairoFontFamily()
    val base = Typography()
    return Typography(
        displayLarge = base.displayLarge.copy(fontFamily = family),
        displayMedium = base.displayMedium.copy(fontFamily = family),
        displaySmall = base.displaySmall.copy(fontFamily = family),
        headlineLarge = base.headlineLarge.copy(fontFamily = family),
        headlineMedium = base.headlineMedium.copy(fontFamily = family),
        headlineSmall = base.headlineSmall.copy(fontFamily = family),
        titleLarge = base.titleLarge.copy(fontFamily = family),
        titleMedium = base.titleMedium.copy(fontFamily = family),
        titleSmall = base.titleSmall.copy(fontFamily = family),
        bodyLarge = base.bodyLarge.copy(fontFamily = family),
        bodyMedium = base.bodyMedium.copy(fontFamily = family),
        bodySmall = base.bodySmall.copy(fontFamily = family),
        labelLarge = base.labelLarge.copy(fontFamily = family),
        labelMedium = base.labelMedium.copy(fontFamily = family),
        labelSmall = base.labelSmall.copy(fontFamily = family),
    )
}
