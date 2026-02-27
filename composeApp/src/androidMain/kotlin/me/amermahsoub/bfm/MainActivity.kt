package me.amermahsoub.bfm

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import me.amermahsoub.bfm.shared.data.tenant.tenantBootstrapModule
import me.amermahsoub.bfm.shared.printing.printingModule
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        if (GlobalContext.getOrNull() == null) {
            startKoin {
                androidContext(this@MainActivity)
                modules(tenantBootstrapModule(), printingModule())
            }
        }

        setContent { App() }
    }
}
