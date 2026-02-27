package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

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
    val primaryColorHex: String? = null,
    val backgroundColorHex: String? = null,
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
data class TenantConfigApiResponse(
    val tenant: TenantApiInfo,
    val theme: TenantThemeApiInfo,
    val currency: TenantCurrencyApiInfo,
)

@Serializable
data class TenantApiInfo(
    val id: Long,
    val name: String,
    val slug: String,
    @SerialName("logo_url") val logoUrl: String? = null,
)

@Serializable
data class TenantThemeApiInfo(
    val primaryColor: String? = null,
    val secondaryColor: String? = null,
    val accentColor: String? = null,
    val backgroundColor: String? = null,
    val textColor: String? = null,
    val logoUrl: String? = null,
    val faviconUrl: String? = null,
)

@Serializable
data class TenantCurrencyApiInfo(
    val code: String,
    val name: String,
    val symbol: String,
)
