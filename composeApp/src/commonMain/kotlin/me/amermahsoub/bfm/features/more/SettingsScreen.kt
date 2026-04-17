package me.amermahsoub.bfm.features.more

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle

@Composable
fun SettingsScreen(
    currentLocale: String,
    onLocaleChange: (String) -> Unit,
    currentDark: Boolean,
    onDarkChange: (Boolean) -> Unit,
) {
    val strings = appStrings()
    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.settings)
        SectionTitle(strings.language)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = currentLocale == "en",
                onClick = { onLocaleChange("en") },
                label = { Text("English") },
            )
            FilterChip(
                selected = currentLocale == "ar",
                onClick = { onLocaleChange("ar") },
                label = { Text("العربية") },
            )
        }
        SectionTitle(strings.theme)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = !currentDark,
                onClick = { onDarkChange(false) },
                label = { Text(strings.lightMode) },
            )
            FilterChip(
                selected = currentDark,
                onClick = { onDarkChange(true) },
                label = { Text(strings.darkMode) },
            )
        }
    }
}
