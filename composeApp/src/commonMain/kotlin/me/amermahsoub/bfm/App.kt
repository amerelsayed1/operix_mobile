package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.ProvideAppStrings
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.nav.AppNavigator
import me.amermahsoub.bfm.app.nav.LocalAppNavigator
import me.amermahsoub.bfm.app.nav.Route
import me.amermahsoub.bfm.app.nav.rememberAppNavigator
import me.amermahsoub.bfm.app.permission.LocalPermissionGuard
import me.amermahsoub.bfm.app.theme.TenantTheme
import me.amermahsoub.bfm.features.accounts.AccountDetailScreen
import me.amermahsoub.bfm.features.accounts.AccountMoneyFormScreen
import me.amermahsoub.bfm.features.accounts.AccountsListScreen
import me.amermahsoub.bfm.features.accounts.MoneyFormMode
import me.amermahsoub.bfm.features.auth.LoginScreen
import me.amermahsoub.bfm.features.clients.ClientDetailScreen
import me.amermahsoub.bfm.features.clients.ClientFormScreen
import me.amermahsoub.bfm.features.clients.ClientsListScreen
import me.amermahsoub.bfm.features.clients.RecordClientPaymentScreen
import me.amermahsoub.bfm.features.expenses.ExpenseFormScreen
import me.amermahsoub.bfm.features.expenses.ExpensesListScreen
import me.amermahsoub.bfm.features.home.HomeScreen
import me.amermahsoub.bfm.features.inventory.InventoryDetailScreen
import me.amermahsoub.bfm.features.inventory.InventoryListScreen
import me.amermahsoub.bfm.features.more.SettingsScreen
import me.amermahsoub.bfm.features.pos.CashMovementScreen
import me.amermahsoub.bfm.features.pos.scanner.BarcodeScannerScreen
import me.amermahsoub.bfm.features.pos.CloseShiftScreen
import me.amermahsoub.bfm.features.pos.OpenShiftScreen
import me.amermahsoub.bfm.features.pos.PosOrderDetailScreen
import me.amermahsoub.bfm.features.pos.PosOrdersScreen
import me.amermahsoub.bfm.features.pos.ShiftHistoryScreen
import me.amermahsoub.bfm.features.products.ProductDetailScreen
import me.amermahsoub.bfm.features.products.ProductsListScreen
import me.amermahsoub.bfm.features.profile.ChangePasswordScreen
import me.amermahsoub.bfm.features.profile.EditProfileScreen
import me.amermahsoub.bfm.features.profile.ProfileScreen
import me.amermahsoub.bfm.shared.data.tenant.ConfigStore
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.shared.domain.permissions.PermissionGuard
import org.koin.core.context.GlobalContext
import androidx.compose.runtime.rememberCoroutineScope

@Composable
fun App() {
    val koin = GlobalContext.get()
    val tenantRepository = remember { koin.get<TenantRepository>() }
    val tenantContext = remember { koin.get<TenantContext>() }
    val configStore = remember { koin.get<ConfigStore>() }
    val sessionStore = remember { koin.get<SessionStore>() }

    val selectedSlug by tenantRepository.getSelectedTenantSlug().collectAsState(initial = null)
    val tenantConfig by configStore.config.collectAsState()
    val session by sessionStore.session.collectAsState()

    val appScope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }

    // User preferences (local state — persisted elsewhere would be ideal)
    var localeOverride by rememberSaveable { mutableStateOf<String?>(null) }
    var darkTheme by rememberSaveable { mutableStateOf(false) }
    var sessionRestored by remember { mutableStateOf(false) }

    // Hydrate any persisted session on cold start so the user doesn't have to
    // log in again after closing the app.
    LaunchedEffect(Unit) {
        runCatching { tenantRepository.restoreSession() }
        sessionRestored = true
    }

    LaunchedEffect(selectedSlug) {
        tenantContext.setTenantSlug(selectedSlug)
    }

    val effectiveLocale = localeOverride
        ?: session?.me?.locale
        ?: session?.login?.tenant?.locale
        ?: tenantConfig?.localeDefault
        ?: "en"

    val primaryHex = session?.login?.tenant?.themePrimaryColor
    val permissions = session?.let { s ->
        s.permissions.ifEmpty { listOf("*") }
    }.orEmpty()
    val guard = remember(permissions) { PermissionGuard(permissions.toSet()) }

    val navigator: AppNavigator = rememberAppNavigator(if (session == null) Route.Login else Route.Home)

    // Drive navigator state transitions based on session
    LaunchedEffect(session == null) {
        if (session == null) {
            if (navigator.current !is Route.Login) navigator.reset(Route.Login)
        } else {
            if (navigator.current is Route.Login) navigator.reset(Route.Home)
        }
    }

    ProvideAppStrings(effectiveLocale) {
        TenantTheme(primaryColorHex = primaryHex, darkTheme = darkTheme) {
            CompositionLocalProvider(
                LocalAppNavigator provides navigator,
                LocalPermissionGuard provides guard,
                LocalLayoutDirection provides appStrings().layoutDirection,
            ) {
                Scaffold(
                    snackbarHost = { SnackbarHost(snackbar) },
                ) { padding ->
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .safeContentPadding(),
                    ) {
                        if (!sessionRestored) {
                            me.amermahsoub.bfm.app.ui.LoadingState()
                            return@Box
                        }
                        when (val route = navigator.current) {
                            Route.Login -> LoginScreen(
                                initialTenantSlug = selectedSlug,
                                tenantName = tenantConfig?.name,
                                primaryColorHex = primaryHex,
                                onAuthenticated = { navigator.reset(Route.Home) },
                            )
                            Route.Home -> HomeScreen(
                                onLogout = {
                                    appScope.launch {
                                        tenantRepository.logout()
                                        navigator.reset(Route.Login)
                                    }
                                },
                            )

                            // POS
                            Route.PosCart -> HomeScreen(onLogout = {})
                            Route.PosOrders -> PosOrdersScreen(onOrderClick = { id -> navigator.push(Route.PosOrderDetail(id)) })
                            is Route.PosOrderDetail -> PosOrderDetailScreen(route.id)
                            Route.OpenShift -> OpenShiftScreen(onOpened = { navigator.pop() }, onCancel = { navigator.pop() })
                            Route.CloseShift -> CloseShiftScreen(onClosed = { navigator.pop() })
                            Route.CashMovement -> CashMovementScreen(onSaved = { navigator.pop() })
                            Route.ShiftHistory -> ShiftHistoryScreen()
                            Route.BarcodeScanner -> BarcodeScannerScreen(
                                onScanned = { barcode ->
                                    navigator.popWithResult("barcode", barcode)
                                },
                                onClose = { navigator.pop() },
                            )

                            // Clients
                            Route.ClientsList -> ClientsListScreen(
                                onClient = { id -> navigator.push(Route.ClientDetail(id)) },
                                onAddClient = { navigator.push(Route.ClientForm()) },
                            )
                            is Route.ClientDetail -> ClientDetailScreen(
                                id = route.id,
                                onEdit = { navigator.push(Route.ClientForm(route.id)) },
                                onRecordPayment = { navigator.push(Route.RecordClientPayment(route.id)) },
                            )
                            is Route.ClientForm -> ClientFormScreen(existingId = route.id, onSaved = { navigator.pop() })
                            is Route.RecordClientPayment -> RecordClientPaymentScreen(route.clientId, onSaved = { navigator.pop() })

                            // Products & Inventory
                            Route.ProductsList -> ProductsListScreen(onProduct = { id -> navigator.push(Route.ProductDetail(id)) })
                            is Route.ProductDetail -> ProductDetailScreen(route.id)
                            Route.InventoryList -> InventoryListScreen(onInventory = { id -> navigator.push(Route.InventoryDetail(id)) })
                            is Route.InventoryDetail -> InventoryDetailScreen(route.id)

                            // Expenses
                            Route.ExpensesList -> ExpensesListScreen(
                                onAdd = { navigator.push(Route.ExpenseForm()) },
                                onEdit = { id -> navigator.push(Route.ExpenseForm(id)) },
                            )
                            is Route.ExpenseForm -> ExpenseFormScreen(existingId = route.id, onSaved = { navigator.pop() })

                            // Accounts
                            Route.AccountsList -> AccountsListScreen(
                                onAccount = { id -> navigator.push(Route.AccountDetail(id)) },
                                onDeposit = { navigator.push(Route.AccountDepositForm()) },
                                onWithdraw = { navigator.push(Route.AccountWithdrawForm()) },
                                onTransfer = { navigator.push(Route.AccountTransferForm) },
                            )
                            is Route.AccountDetail -> AccountDetailScreen(route.id)
                            is Route.AccountDepositForm -> AccountMoneyFormScreen(
                                mode = MoneyFormMode.DEPOSIT,
                                preselectedAccount = route.accountId,
                                onSaved = { navigator.pop() },
                            )
                            is Route.AccountWithdrawForm -> AccountMoneyFormScreen(
                                mode = MoneyFormMode.WITHDRAW,
                                preselectedAccount = route.accountId,
                                onSaved = { navigator.pop() },
                            )
                            Route.AccountTransferForm -> AccountMoneyFormScreen(
                                mode = MoneyFormMode.TRANSFER,
                                preselectedAccount = null,
                                onSaved = { navigator.pop() },
                            )

                            // Profile
                            Route.Profile -> ProfileScreen(
                                onEdit = { navigator.push(Route.EditProfile) },
                                onChangePassword = { navigator.push(Route.ChangePassword) },
                                onLogout = {
                                    appScope.launch {
                                        tenantRepository.logout()
                                        navigator.reset(Route.Login)
                                    }
                                },
                            )
                            Route.EditProfile -> EditProfileScreen(onSaved = { navigator.pop() })
                            Route.ChangePassword -> ChangePasswordScreen(onDone = { navigator.pop() })

                            // Misc
                            Route.BillingStatus -> ProfileScreen(
                                onEdit = {}, onChangePassword = {}, onLogout = {},
                            )
                            Route.Settings -> SettingsScreen(
                                currentLocale = effectiveLocale,
                                onLocaleChange = { localeOverride = it },
                                currentDark = darkTheme,
                                onDarkChange = { darkTheme = it },
                            )
                        }
                    }
                }
            }
        }
    }
}
