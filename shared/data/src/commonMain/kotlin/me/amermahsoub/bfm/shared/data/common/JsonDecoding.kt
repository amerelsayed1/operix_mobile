package me.amermahsoub.bfm.shared.data.common

import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import me.amermahsoub.bfm.shared.domain.common.Paginated

/**
 * Decodes a Laravel response, unwrapping the top-level `{data: ...}` envelope if present.
 */
internal suspend fun <T> Json.decodeData(
    strategy: DeserializationStrategy<T>,
    request: suspend () -> HttpResponse,
): T {
    val payload = decodePayload(request)
    return try {
        decodeFromJsonElement(strategy, payload)
    } catch (e: SerializationException) {
        throw RuntimeException("Unexpected response format: ${e.message}")
    }
}

internal suspend fun Json.decodePayload(request: suspend () -> HttpResponse): JsonElement {
    val responseText = try {
        request().bodyAsText()
    } catch (e: ClientRequestException) {
        throw e
    } catch (e: Throwable) {
        throw RuntimeException("Unable to reach tenant API: ${e.message}", e)
    }

    val root = try {
        parseToJsonElement(responseText)
    } catch (e: SerializationException) {
        throw RuntimeException("Invalid JSON response: ${e.message}")
    }

    return (root as? JsonObject)?.get("data") ?: root
}

internal suspend fun <T> Json.decodePaginated(
    itemStrategy: DeserializationStrategy<T>,
    request: suspend () -> HttpResponse,
): Paginated<T> {
    val responseText = try {
        request().bodyAsText()
    } catch (e: ClientRequestException) {
        throw e
    } catch (e: Throwable) {
        throw RuntimeException("Unable to reach API: ${e.message}", e)
    }

    val root = parseToJsonElement(responseText) as? JsonObject
        ?: return Paginated.empty()

    val dataElement = root["data"]
    val metaElement = root["meta"]

    val items: List<T> = when (dataElement) {
        is kotlinx.serialization.json.JsonArray -> dataElement.map { decodeFromJsonElement(itemStrategy, it) }
        else -> emptyList()
    }

    val meta = metaElement?.let {
        runCatching { decodeFromJsonElement(PaginationMeta.serializer(), it) }.getOrNull()
    }

    return Paginated(
        data = items,
        currentPage = meta?.currentPage ?: 1,
        lastPage = meta?.lastPage ?: 1,
        perPage = meta?.perPage ?: items.size.coerceAtLeast(15),
        total = meta?.total ?: items.size,
    )
}
