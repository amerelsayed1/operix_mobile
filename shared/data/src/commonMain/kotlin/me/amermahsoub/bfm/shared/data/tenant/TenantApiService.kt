package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

class TenantApiService(
    private val httpClient: HttpClient,
    private val urlBuilder: TenantAwareApiUrlBuilder,
    private val json: Json,
    private val sessionStore: SessionStore,
) {
    suspend fun fetchBootstrap(slug: String): TenantBootstrapResponse {
        val publicConfig = fetchPublicTenantConfig(slug)
        val systemConfig = fetchSystemConfig(slug)
        return TenantBootstrapResponse(
            tenant = TenantConfig(
                slug = publicConfig.slug,
                name = publicConfig.name,
                currency = publicConfig.currencyCode ?: "USD",
                timezone = publicConfig.timezone ?: "UTC",
                localeDefault = publicConfig.locale ?: "en",
                pos = PosConfig(
                    taxIncluded = false,
                    defaultTaxRate = 0.0,
                    receiptCharsPerLine = 42,
                ),
            ),
            features = TenantFeatures(pos = true, inventory = true, accounting = true),
            app = systemConfig.app ?: AppConfig(minVersion = "1.0.0", forceUpdate = false),
        )
    }

    suspend fun fetchPublicTenantConfig(slug: String): PublicTenantConfig =
        decodeResponse(PublicTenantConfig.serializer()) { httpClient.get(urlBuilder.publicTenantConfig(slug)) }

    suspend fun fetchSystemConfig(slug: String): TenantSystemConfig =
        decodeResponse(TenantSystemConfig.serializer()) { httpClient.get(urlBuilder.systemConfig(slug)) }

    suspend fun login(slug: String, username: String, password: String): LoginResponse =
        decodeResponse(LoginResponse.serializer()) {
            httpClient.post(urlBuilder.login(slug)) {
                contentType(ContentType.Application.Json)
                setBody(LoginRequest(username, password))
            }
        }

    suspend fun logout() {
        authorizedPost(urlBuilder.logout())
        sessionStore.clear()
    }

    suspend fun fetchCurrentUser(): SessionUser =
        decodeResponse(SessionUser.serializer()) { authorizedGet(urlBuilder.me()) }

    suspend fun fetchPermissions(): List<String> {
        val payload = decodePayload { authorizedGet(urlBuilder.permissions()) }
        return when (payload) {
            is JsonArray -> {
                runCatching {
                    json.decodeFromJsonElement(ListSerializer(PermissionEntry.serializer()), payload)
                        .mapNotNull { it.code ?: it.slug ?: it.name }
                }.getOrElse {
                    json.decodeFromJsonElement(ListSerializer(String.serializer()), payload)
                }
            }
            else -> emptyList()
        }
    }

    suspend fun fetchProtectedConfig(): ProtectedTenantConfig =
        decodeResponse(ProtectedTenantConfig.serializer()) { authorizedGet(urlBuilder.config()) }

    suspend fun fetchDashboardKpis(): DashboardKpisResponse =
        decodeResponse(DashboardKpisResponse.serializer()) { authorizedGet(urlBuilder.dashboardKpis()) }

    suspend fun fetchLowStock(): List<LowStockItem> =
        decodeResponse(ListSerializer(LowStockItem.serializer())) { authorizedGet(urlBuilder.lowStock()) }

    suspend fun fetchRecentOrders(): List<RecentOrderItem> =
        decodeResponse(ListSerializer(RecentOrderItem.serializer())) { authorizedGet(urlBuilder.recentOrders()) }

    private suspend fun authorizedGet(url: String): HttpResponse =
        httpClient.get(url) { applyAuthorization() }

    private suspend fun authorizedPost(url: String): HttpResponse =
        httpClient.post(url) { applyAuthorization() }

    private fun io.ktor.client.request.HttpRequestBuilder.applyAuthorization() {
        val token = sessionStore.token ?: error("No active session token")
        header(HttpHeaders.Authorization, "Bearer $token")
    }

    private suspend fun <T> decodeResponse(
        strategy: DeserializationStrategy<T>,
        request: suspend () -> HttpResponse,
    ): T = try {
        json.decodeFromJsonElement(strategy, decodePayload(request))
    } catch (e: SerializationException) {
        throw RuntimeException("Unexpected response format: ${e.message}")
    }

    private suspend fun decodePayload(request: suspend () -> HttpResponse): JsonElement {
        val responseText = try {
            request().bodyAsText()
        } catch (e: ClientRequestException) {
            throw RuntimeException("Request failed: ${e.response.status}")
        } catch (e: Throwable) {
            throw RuntimeException("Unable to reach tenant API: ${e.message}")
        }

        val root = try {
            json.parseToJsonElement(responseText)
        } catch (e: SerializationException) {
            throw RuntimeException("Invalid JSON response: ${e.message}")
        }
        return (root as? JsonObject)?.get("data") ?: root
    }
}
