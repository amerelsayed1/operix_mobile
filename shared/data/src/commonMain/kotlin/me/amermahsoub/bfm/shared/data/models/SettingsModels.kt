package me.amermahsoub.bfm.shared.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// ── Currency ─────────────────────────────────────────────────────────────

@Serializable
data class Currency(
    val id: Int,
    val code: String,
    val name: String,
    val symbol: String? = null,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("exchange_rate") val exchangeRate: String = "1.000000",
)

// ── Tax ───────────────────────────────────────────────────────────────────

@Serializable
data class Tax(
    val id: Int,
    val name: String,
    @SerialName("name_ar") val nameAr: String? = null,
    val rate: String,
    @SerialName("is_compound") val isCompound: Boolean = false,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true,
) {
    fun displayName(locale: String = "en") =
        if (locale == "ar") nameAr ?: name else name
}

@Serializable
data class TaxConfig(
    @SerialName("tax_inclusive") val taxInclusive: Boolean = false,
    @SerialName("default_tax_id") val defaultTaxId: Int? = null,
    @SerialName("show_tax_on_receipt") val showTaxOnReceipt: Boolean = true,
)

// ── Employee ──────────────────────────────────────────────────────────────

@Serializable
data class EmployeeRole(
    val id: Int,
    val name: String,
)

@Serializable
data class Employee(
    val id: Int,
    val name: String,
    val email: String,
    val phone: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("last_login_at") val lastLoginAt: String? = null,
    val role: EmployeeRole? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class CreateEmployeeRequest(
    val name: String,
    val email: String,
    val password: String,
    @SerialName("password_confirmation") val passwordConfirmation: String,
    val phone: String? = null,
    @SerialName("role_id") val roleId: Int,
)

@Serializable
data class UpdateEmployeeStatusRequest(
    @SerialName("is_active") val isActive: Boolean,
)
