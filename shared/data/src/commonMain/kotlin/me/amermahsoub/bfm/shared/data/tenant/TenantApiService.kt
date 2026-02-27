package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.Serializable

class TenantApiService(
    private val httpClient: HttpClient,
    private val urlBuilder: TenantAwareApiUrlBuilder,
) {
    suspend fun fetchBootstrap(slug: String): TenantBootstrapResponse {
        return try {
            httpClient.get(urlBuilder.bootstrap(slug)).body()
        } catch (e: ClientRequestException) {
            throw RuntimeException("Unable to connect tenant '$slug': ${e.response.status}")
        } catch (e: Throwable) {
            throw RuntimeException("Unable to load tenant config: ${e.message}")
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

@Serializable
data class LoginRequest(val username: String, val password: String)

@Serializable
data class LoginResponse(val token: String, val employeeName: String)
