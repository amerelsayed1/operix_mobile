package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.plugins.RedirectResponseException
import io.ktor.client.plugins.ServerResponseException
import io.ktor.client.plugins.ResponseException
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
            throw RuntimeException("Tenant not found or request invalid for '$slug' (${e.response.status}).")
        } catch (e: RedirectResponseException) {
            throw RuntimeException("Unexpected redirect while loading tenant '$slug'.")
        } catch (e: ServerResponseException) {
            throw RuntimeException("Server error while loading tenant '$slug' (${e.response.status}).")
        } catch (e: ResponseException) {
            throw RuntimeException("HTTP error while loading tenant '$slug'.")
        } catch (e: Throwable) {
            throw RuntimeException("Unable to fetch tenant config. Check base URL, network, and tenant slug.")
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
