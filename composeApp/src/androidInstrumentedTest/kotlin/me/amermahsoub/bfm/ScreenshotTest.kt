package me.amermahsoub.bfm

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import me.amermahsoub.bfm.shared.data.featureModule
import me.amermahsoub.bfm.shared.data.tenant.LoginResponse
import me.amermahsoub.bfm.shared.data.tenant.RoleRef
import me.amermahsoub.bfm.shared.data.tenant.SessionBootstrap
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.SessionTenant
import me.amermahsoub.bfm.shared.data.tenant.SessionUser
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.shared.data.tenant.tenantBootstrapModule
import me.amermahsoub.bfm.shared.printing.printingModule
import org.junit.Before
import org.junit.BeforeClass
import org.junit.Rule
import org.junit.Test
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import tools.fastlane.screengrab.Screengrab
import tools.fastlane.screengrab.UiAutomatorScreenshotStrategy

/**
 * Walks the app's main screens and captures one screenshot per screen via
 * fastlane/screengrab.
 *
 * The test starts Koin with a Ktor [FakeBackend] engine so every screen renders
 * with realistic canned data instead of empty / error states. A synthetic
 * [SessionBootstrap] with broad permissions is pushed into the live
 * [SessionStore] so the app lands on Home.
 */
class ScreenshotTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    companion object {
        @BeforeClass
        @JvmStatic
        fun bootKoinWithFakes() {
            Screengrab.setDefaultScreenshotStrategy(UiAutomatorScreenshotStrategy())

            val ctx = InstrumentationRegistry.getInstrumentation().targetContext

            // If anything already started Koin (e.g. MainActivity from a prior
            // test run in this process), tear it down so we can install the
            // mock engine.
            if (GlobalContext.getOrNull() != null) stopKoin()

            startKoin {
                androidContext(ctx)
                modules(
                    tenantBootstrapModule(
                        baseUrl = "http://operix.mock.local",
                        engineFactory = { FakeBackend.engine() },
                    ),
                    featureModule(),
                    printingModule(),
                )
            }

            // Seed the tenant slug into SQLDelight so the flow App.kt collects
            // emits "demo" immediately. Without this, App's LaunchedEffect
            // would keep overwriting TenantContext with null.
            val repo = GlobalContext.get().get<TenantRepository>()
            runBlocking { repo.selectTenant("demo") }
        }
    }

    @Before
    fun seedSession() {
        val koin = GlobalContext.get()

        // Defensive: also set in-memory tenant context now, in case the
        // SQLDelight flow hasn't emitted yet by the time the first compose
        // frame runs.
        koin.get<TenantContext>().setTenantSlug("demo")

        val user = SessionUser(
            id = 1,
            name = "Demo Owner",
            email = "owner@operix.app",
            phoneNumber = "+1 555 555 0123",
            role = RoleRef(id = 1, name = "Owner"),
            locale = "en",
        )
        val tenant = SessionTenant(
            id = 1,
            slug = "demo",
            name = "Operix Demo",
            currencyCode = "USD",
            locale = "en",
        )

        koin.get<SessionStore>().update(
            SessionBootstrap(
                login = LoginResponse(
                    token = "preview-token",
                    user = user,
                    tenant = tenant,
                ),
                me = user,
                permissions = listOf(
                    "dashboard.view",
                    "pos.view",
                    "pos.create",
                    "pos.shifts.view",
                    "pos.cash_movements.create",
                    "clients.view",
                    "clients.create",
                    "products.view",
                    "inventory.view",
                    "accounts.view",
                    "expenses.view",
                    "expenses.create",
                ),
                tenantConfig = null,
            ),
        )
    }

    @Test
    fun captureAppTour() {
        settle()
        Screengrab.screenshot("01_dashboard")

        tapTab("POS")
        Screengrab.screenshot("02_pos_cart")

        tapTab("Clients")
        Screengrab.screenshot("03_clients")

        tapTab("Products")
        Screengrab.screenshot("04_products")

        tapTab("More")
        Screengrab.screenshot("05_more")

        // "Settings" is the label on both the MoreScreen list row and the
        // destination's ScreenTitle. Index [0] is the list row currently in
        // the composition tree.
        composeRule.onAllNodesWithText("Settings")[0].performClick()
        settle()
        Screengrab.screenshot("06_settings")
    }

    private fun tapTab(label: String) {
        composeRule.onNodeWithText(label).performClick()
        settle()
    }

    /** Waits for compose idle, then pauses briefly so any in-flight repo
     *  calls resolve before capture. */
    private fun settle() {
        composeRule.waitForIdle()
        Thread.sleep(1200)
    }
}
