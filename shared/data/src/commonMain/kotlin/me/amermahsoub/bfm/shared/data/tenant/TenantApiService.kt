package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.utils.io.errors.IOException
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

class TenantApiService(
    private val httpClient: HttpClient,
    private val urlBuilder: TenantAwareApiUrlBuilder,
) {
    suspend fun fetchTenantConfig(slug: String): TenantConfig {
        return try {
            val response = httpClient.get(urlBuilder.tenantConfig(slug)).body<TenantConfigApiResponse>()
            response.toTenantConfig()
        } catch (e: ClientRequestException) {
            if (e.response.status.value == 404) {
                throw TenantConfigLoadException.NotFound
            }
            throw TenantConfigLoadException.Unknown
        } catch (e: IOException) {
            throw TenantConfigLoadException.Network
        } catch (e: Throwable) {
            throw TenantConfigLoadException.Unknown
        }
    }

    suspend fun login(username: String, password: String): LoginResponse {
        return try {
            val response = httpClient.post(urlBuilder.login()) {
                contentType(ContentType.Application.Json)
                setBody(LoginRequest(username, password))
            }

            when {
                response.status.value == 401 -> throw RuntimeException("Invalid email or password.")
                !response.status.isSuccess() -> throw RuntimeException("Login failed: ${response.status}")
                else -> response.body()
            }
        } catch (e: RuntimeException) {
            throw e
        } catch (e: Throwable) {
            throw RuntimeException("Login failed: ${e.message}")
        }
    }
}

sealed class TenantConfigLoadException : RuntimeException() {
    data object NotFound : TenantConfigLoadException()
    data object Network : TenantConfigLoadException()
    data object Unknown : TenantConfigLoadException()
}

@Serializable
data class LoginRequest(val username: String, val password: String)

@Serializable
data class LoginResponse(
    val token: String,
    @SerialName("token_type") val tokenType: String,
    @SerialName("expires_in") val expiresIn: Long,
    val user: LoginUser,
    val tenant: LoginTenant,
    @SerialName("redirect_to") val redirectTo: String,
)

@Serializable
data class LoginUser(
    val id: Long,
    val name: String,
    val email: String,
    @SerialName("business_name") val businessName: String? = null,
    @SerialName("business_logo") val businessLogo: String? = null,
    @SerialName("default_currency") val defaultCurrency: String? = null,
    @SerialName("theme_mode") val themeMode: String? = null,
    @SerialName("theme_primary_color") val themePrimaryColor: String? = null,
    val role: LoginUserRole,
    @SerialName("role_id") val roleId: Long,
)

@Serializable
data class LoginUserRole(
    val id: Long,
    val name: String,
)

@Serializable
data class LoginTenant(
    val id: Long,
    val name: String,
    val slug: String,
    @SerialName("currency_code") val currencyCode: String,
    val timezone: String,
    val locale: String,
    @SerialName("theme_primary_color") val themePrimaryColor: String? = null,
    @SerialName("logo_url") val logoUrl: String? = null,
)


private fun TenantConfigApiResponse.toTenantConfig(): TenantConfig = TenantConfig(
    slug = tenant.slug,
    name = tenant.name,
    currency = currency.code,
    timezone = "UTC",
    localeDefault = "en",
    pos = PosConfig(
        taxIncluded = false,
        defaultTaxRate = 0.0,
        receiptCharsPerLine = 42,
    ),
    primaryColorHex = theme.primaryColor,
    backgroundColorHex = theme.backgroundColor,
)
