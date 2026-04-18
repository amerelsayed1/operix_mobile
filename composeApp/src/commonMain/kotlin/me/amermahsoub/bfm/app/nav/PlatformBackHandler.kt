package me.amermahsoub.bfm.app.nav

import androidx.compose.runtime.Composable

@Composable
expect fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit)
