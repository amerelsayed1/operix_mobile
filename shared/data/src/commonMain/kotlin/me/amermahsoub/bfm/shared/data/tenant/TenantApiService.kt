package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.utils.io.errors.IOException
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
            httpClient.post(urlBuilder.login()) {
                contentType(ContentType.Application.Json)
                setBody(LoginRequest(username, password))
            }.body()
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
data class LoginResponse(val token: String, val employeeName: String)


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
)
