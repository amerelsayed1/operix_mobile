package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
internal data class ApiEnvelope<T>(
    val success: Boolean? = null,
    val message: String? = null,
    val data: T? = null,
)

@Serializable
internal data class MessageEnvelope(
    val success: Boolean? = null,
    val message: String? = null,
)

@Serializable
data class TenantBootstrapResponse(
    val tenant: TenantConfig,
    val features: TenantFeatures,
    val app: AppConfig,
)

@Serializable
data class TenantConfig(
    val slug: String,
    val name: String,
    val currency: String,
    val timezone: String,
    @SerialName("locale_default") val localeDefault: String,
    val pos: PosConfig,
)

@Serializable
data class PosConfig(
    @SerialName("tax_included") val taxIncluded: Boolean,
    @SerialName("default_tax_rate") val defaultTaxRate: Double,
    @SerialName("receipt_chars_per_line") val receiptCharsPerLine: Int,
)

@Serializable
data class TenantFeatures(
    val pos: Boolean,
    val inventory: Boolean,
    val accounting: Boolean,
)

@Serializable
data class AppConfig(
    @SerialName("min_version") val minVersion: String,
    @SerialName("force_update") val forceUpdate: Boolean,
)

/**
 * Public tenant config returned by `GET /api/v1/tenant-config/{slug}`.
 *
 * The live response is `{ "tenant": { id, slug, name, logo_url },
 * "theme": { primaryColor, ..., logoUrl, appName, themeMode } }`.
 * Accessor properties expose flat fields for legacy call sites.
 */
@Serializable
data class PublicTenantConfig(
    val tenant: PublicTenantInfo,
    val theme: PublicTenantTheme? = null,
) {
    val slug: String get() = tenant.slug
    val name: String get() = theme?.appName ?: tenant.name
    val logoUrl: String? get() = tenant.logoUrl ?: theme?.logoUrl
    val themePrimaryColor: String? get() = theme?.primaryColor
    val locale: String? get() = null
    val localeDirection: String? get() = null
    val currencyCode: String? get() = null
    val timezone: String? get() = null
}

@Serializable
data class PublicTenantInfo(
    val id: Long? = null,
    val slug: String,
    val name: String,
    @SerialName("logo_url") val logoUrl: String? = null,
)

@Serializable
data class PublicTenantTheme(
    val primaryColor: String? = null,
    val secondaryColor: String? = null,
    val accentColor: String? = null,
    val backgroundColor: String? = null,
    val textColor: String? = null,
    val logoUrl: String? = null,
    val faviconUrl: String? = null,
    val appName: String? = null,
    val themeMode: String? = null,
)

@Serializable
data class TenantSystemConfig(
    val tenant: PublicTenantConfig? = null,
    val branding: BrandingConfig? = null,
    val app: AppConfig? = null,
)

@Serializable
data class BrandingConfig(
    @SerialName("business_name") val businessName: String? = null,
    @SerialName("logo_url") val logoUrl: String? = null,
    @SerialName("theme_primary_color") val themePrimaryColor: String? = null,
)

@Serializable
data class LoginRequest(
    val email: String,
    val password: String,
    @SerialName("remember_me") val rememberMe: Boolean = false,
)

@Serializable
data class LoginResponse(
    val token: String,
    @SerialName("token_type") val tokenType: String = "Bearer",
    @SerialName("expires_in") val expiresIn: Long? = null,
    @SerialName("remember_me") val rememberMe: Boolean = false,
    val user: SessionUser,
    val tenant: SessionTenant? = null,
    @SerialName("redirect_to") val redirectTo: String? = null,
)

@Serializable
data class SessionTenant(
    val id: Long? = null,
    val slug: String,
    val name: String? = null,
    @SerialName("currency_code") val currencyCode: String? = null,
    val timezone: String? = null,
    val locale: String? = null,
    @SerialName("theme_primary_color") val themePrimaryColor: String? = null,
    @SerialName("logo_url") val logoUrl: String? = null,
)

@Serializable
data class SessionUser(
    val id: Long? = null,
    val name: String,
    val email: String? = null,
    @SerialName("phone") val phoneNumber: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("tenant_id") val tenantId: Long? = null,
    @SerialName("role_id") val roleId: Long? = null,
    val role: RoleRef? = null,
    val roles: List<String> = emptyList(),
    val locale: String? = null,
    @SerialName("business_name") val businessName: String? = null,
    @SerialName("business_logo") val businessLogo: String? = null,
    @SerialName("default_currency") val defaultCurrency: String? = null,
    @SerialName("theme_mode") val themeMode: String? = null,
    @SerialName("theme_primary_color") val themePrimaryColor: String? = null,
    @SerialName("drawer_account") val drawerAccount: AccountRef? = null,
    @SerialName("default_account") val defaultAccount: AccountRef? = null,
) {
    val roleName: String? get() = role?.name
}

@Serializable
data class RoleRef(
    val id: Long? = null,
    val name: String? = null,
)

@Serializable
data class AccountRef(
    val id: Long? = null,
    val name: String? = null,
)

@Serializable
data class PermissionEntry(
    val id: Long? = null,
    val name: String? = null,
    val slug: String? = null,
    val code: String? = null,
)

@Serializable
data class ProtectedTenantConfig(
    val tenant: SessionTenant? = null,
    @SerialName("default_inventory_id") val defaultInventoryId: Long? = null,
    @SerialName("default_branch_id") val defaultBranchId: Long? = null,
    @SerialName("drawer_required") val drawerRequired: Boolean? = null,
    @SerialName("raw") val rawPayload: JsonElement? = null,
)

@Serializable
data class DashboardKpisResponse(
    val items: List<DashboardKpiItem> = emptyList(),
)

@Serializable
data class DashboardKpiItem(
    val key: String,
    val label: String,
    val value: String,
    val change: String? = null,
)

@Serializable
data class LowStockItem(
    val id: Long? = null,
    val name: String,
    val sku: String? = null,
    @SerialName("available_qty") val availableQty: Double? = null,
    @SerialName("minimum_qty") val minimumQty: Double? = null,
)

@Serializable
data class RecentOrderItem(
    val id: Long? = null,
    val number: String? = null,
    val customer: String? = null,
    val total: String? = null,
    val status: String? = null,
)

@Serializable
data class SessionBootstrap(
    val login: LoginResponse,
    val me: SessionUser,
    val permissions: List<String>,
    val tenantConfig: ProtectedTenantConfig? = null,
)
