package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class TenantApiService(
    private val httpClient: HttpClient,
    private val urlBuilder: TenantAwareApiUrlBuilder,
    private val json: Json,
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

    suspend fun fetchPublicTenantConfig(slug: String): PublicTenantConfig {
        val payload = decodePayload { httpClient.get(urlBuilder.publicTenantConfig(slug)) }
        return decodePublicTenantConfig(payload)
    }

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
        httpClient.post(urlBuilder.logout())
    }

    suspend fun fetchCurrentUser(): SessionUser =
        decodeResponse(SessionUser.serializer()) { httpClient.get(urlBuilder.me()) }

    suspend fun fetchPermissions(): List<String> {
        val payload = decodePayload { httpClient.get(urlBuilder.permissions()) }
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
        decodeResponse(ProtectedTenantConfig.serializer()) { httpClient.get(urlBuilder.config()) }

    suspend fun fetchDashboardKpis(): DashboardKpisResponse =
        decodeResponse(DashboardKpisResponse.serializer()) { httpClient.get(urlBuilder.dashboardKpis()) }

    suspend fun fetchLowStock(): List<LowStockItem> =
        decodeResponse(ListSerializer(LowStockItem.serializer())) { httpClient.get(urlBuilder.lowStock()) }

    suspend fun fetchRecentOrders(): List<RecentOrderItem> =
        decodeResponse(ListSerializer(RecentOrderItem.serializer())) { httpClient.get(urlBuilder.recentOrders()) }

    internal fun decodePublicTenantConfig(payload: JsonElement): PublicTenantConfig {
        val normalizedPayload = normalizePublicTenantConfigPayload(payload)
        return try {
            json.decodeFromJsonElement(PublicTenantConfig.serializer(), normalizedPayload)
        } catch (e: SerializationException) {
            throw RuntimeException("Unexpected response format: ${e.message}")
        }
    }

    private fun normalizePublicTenantConfigPayload(payload: JsonElement): JsonElement {
        val root = payload as? JsonObject ?: return payload
        if ("slug" in root && "name" in root) return payload

        val tenant = root["tenant"]?.jsonObject ?: return payload
        val theme = root["theme"]?.jsonObject

        return buildJsonObject {
            put("slug", tenant["slug"] ?: run {
                val slugValue = tenant["name"]?.jsonPrimitive?.contentOrNull
                    ?.trim()
                    ?.lowercase()
                    ?.replace(Regex("[^a-z0-9]+"), "-")
                    ?.trim('-')
                slugValue?.let { kotlinx.serialization.json.JsonPrimitive(it) }
                    ?: throw RuntimeException("Unexpected response format: tenant slug is missing")
            })
            put("name", tenant["name"] ?: throw RuntimeException("Unexpected response format: tenant name is missing"))
            put("logo_url", tenant["logo_url"] ?: theme?.get("logoUrl"))
            put("locale", tenant["locale"])
            put("locale_direction", tenant["locale_direction"])
            put("theme_primary_color", tenant["theme_primary_color"] ?: theme?.get("primaryColor"))
            put("currency_code", tenant["currency_code"])
            put("timezone", tenant["timezone"])
        }
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
