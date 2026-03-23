package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals

class TenantApiServiceTest {
    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
    }

    private val service = TenantApiService(
        httpClient = HttpClient(),
        urlBuilder = TenantAwareApiUrlBuilder("http://localhost:8000", TenantContext()),
        json = json,
    )

    @Test
    fun decodesNestedTenantConfigResponse() {
        val payload = json.parseToJsonElement(
            """
            {
              "tenant": {
                "id": 5,
                "name": "Style shop",
                "slug": "style-shop",
                "logo_url": "http://192.168.1.33:8000/storage/tenant-5/logos/logo.png"
              },
              "theme": {
                "primaryColor": "#f26479",
                "secondaryColor": "#1b1b1d",
                "accentColor": "#f59e0b",
                "backgroundColor": "#f3f4f6",
                "textColor": "#111827",
                "logoUrl": "http://192.168.1.33:8000/storage/tenant-5/logos/logo.png",
                "faviconUrl": null,
                "appName": "Style shop",
                "themeMode": "light"
              }
            }
            """.trimIndent(),
        )

        val config = service.decodePublicTenantConfig(payload)

        assertEquals("style-shop", config.slug)
        assertEquals("Style shop", config.name)
        assertEquals("http://192.168.1.33:8000/storage/tenant-5/logos/logo.png", config.logoUrl)
        assertEquals("#f26479", config.themePrimaryColor)
    }
}
