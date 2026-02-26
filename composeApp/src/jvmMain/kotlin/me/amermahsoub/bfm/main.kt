package me.amermahsoub.bfm

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "Bfm",
    ) {
        App()
    }
}