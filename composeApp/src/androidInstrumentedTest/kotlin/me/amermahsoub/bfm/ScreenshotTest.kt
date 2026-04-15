package me.amermahsoub.bfm

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import me.amermahsoub.bfm.shared.data.tenant.LoginResponse
import me.amermahsoub.bfm.shared.data.tenant.SessionBootstrap
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.SessionTenant
import me.amermahsoub.bfm.shared.data.tenant.SessionUser
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.koin.core.context.GlobalContext
import tools.fastlane.screengrab.Screengrab
import tools.fastlane.screengrab.UiAutomatorScreenshotStrategy

/**
 * Walks the app's main screens and captures one screenshot per screen via
 * fastlane/screengrab.
 *
 * The test seeds a synthetic [SessionBootstrap] directly into the running
 * [SessionStore] so the app lands on Home instead of Login. Repository
 * network calls for the dashboard / lists will fail on an offline emulator,
 * which is expected — each screen still renders chrome + error/empty state
 * which is what the screenshots demonstrate. Point the emulator at a real
 * tenant backend (via `local.properties` BASE_URL) to get populated data.
 */
class ScreenshotTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun seedSession() {
        Screengrab.setDefaultScreenshotStrategy(UiAutomatorScreenshotStrategy())

        val koin = GlobalContext.get()
        val sessionStore = koin.get<SessionStore>()

        val user = SessionUser(
            id = 1,
            name = "Demo Owner",
            email = "owner@operix.app",
            phoneNumber = "+15555550123",
            role = "Owner",
            locale = "en",
        )
        val tenant = SessionTenant(
            id = 1,
            slug = "demo",
            name = "Operix Demo",
            currencyCode = "USD",
            locale = "en",
        )

        sessionStore.update(
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

        // "Settings" entry lives under the More hub. It's also the label on
        // the destination screen, so match the first node (which is the list
        // row) to navigate.
        composeRule.onAllNodesWithText("Settings")[0].performClick()
        settle()
        Screengrab.screenshot("06_settings")
    }

    private fun tapTab(label: String) {
        composeRule.onNodeWithText(label).performClick()
        settle()
    }

    /** Waits for compose idle, then pauses briefly so any in-flight repo
     *  calls have a chance to resolve to an error/empty state before capture. */
    private fun settle() {
        composeRule.waitForIdle()
        Thread.sleep(1200)
    }
}
