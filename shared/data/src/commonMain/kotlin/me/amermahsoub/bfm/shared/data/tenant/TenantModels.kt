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

@Serializable
data class PublicTenantConfig(
    val slug: String,
    val name: String,
    @SerialName("logo_url") val logoUrl: String? = null,
    val locale: String? = null,
    @SerialName("locale_direction") val localeDirection: String? = null,
    @SerialName("theme_primary_color") val themePrimaryColor: String? = null,
    @SerialName("currency_code") val currencyCode: String? = null,
    val timezone: String? = null,
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
data class LoginRequest(val username: String, val password: String)

@Serializable
data class LoginResponse(
    val token: String,
    @SerialName("token_type") val tokenType: String = "Bearer",
    @SerialName("expires_in") val expiresIn: Long? = null,
    val user: SessionUser,
    val tenant: SessionTenant,
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
    @SerialName("role_id") val roleId: Long? = null,
    val role: String? = null,
    val locale: String? = null,
    @SerialName("drawer_account") val drawerAccount: AccountRef? = null,
    @SerialName("default_account") val defaultAccount: AccountRef? = null,
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
