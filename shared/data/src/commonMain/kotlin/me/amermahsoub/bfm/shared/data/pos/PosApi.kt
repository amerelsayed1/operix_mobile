package me.amermahsoub.bfm.shared.data.pos

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

class PosApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    // --- Reference data ----------------------------------------------------
    suspend fun products(search: String? = null): Paginated<PosProduct> =
        json.decodePaginated(PosProduct.serializer()) {
            client.get(urls.posProducts()) { search?.let { parameter("search", it) } }
        }

    suspend fun paymentMethods(): List<PaymentMethodDto> =
        json.decodeData(ListSerializer(PaymentMethodDto.serializer())) {
            client.get(urls.posPaymentMethods())
        }

    suspend fun accounts(): List<PosAccountDto> =
        json.decodeData(ListSerializer(PosAccountDto.serializer())) { client.get(urls.posAccounts()) }

    suspend fun taxes(): List<TaxDto> =
        json.decodeData(ListSerializer(TaxDto.serializer())) { client.get(urls.posTaxes()) }

    // --- Shift -------------------------------------------------------------
    suspend fun currentShift(): Shift? =
        runCatching {
            json.decodeData(Shift.serializer()) { client.get(urls.posShiftCurrent()) }
        }.getOrNull()

    suspend fun openShift(req: ShiftOpenRequest): Shift =
        json.decodeData(Shift.serializer()) {
            client.post(urls.posShiftOpen()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun closeShift(req: ShiftCloseRequest): Shift =
        json.decodeData(Shift.serializer()) {
            client.post(urls.posShiftClose()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun shiftSummary(): ShiftSummary =
        json.decodeData(ShiftSummary.serializer()) { client.get(urls.posShiftSummary()) }

    suspend fun shiftHistory(page: Int = 1, perPage: Int = 20): Paginated<Shift> =
        json.decodePaginated(Shift.serializer()) {
            client.get(urls.posShiftHistory()) {
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun addCashMovement(req: CashMovementRequest): CashMovement =
        json.decodeData(CashMovement.serializer()) {
            client.post(urls.posShiftCashMovements()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun availableDrawers(): List<PosAccountDto> =
        json.decodeData(ListSerializer(PosAccountDto.serializer())) {
            client.get(urls.posShiftAvailableDrawers())
        }

    // --- Orders ------------------------------------------------------------
    suspend fun listOrders(
        status: String? = null,
        clientId: Long? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): Paginated<PosOrder> =
        json.decodePaginated(PosOrder.serializer()) {
            client.get(urls.posOrders()) {
                status?.let { parameter("status", it) }
                clientId?.let { parameter("client_id", it) }
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun createOrder(req: PosOrderCreateRequest): PosOrder {
        // POS create wraps the order under "pos_order" or top-level "data"
        val response = client.post(urls.posOrders()) {
            contentType(ContentType.Application.Json)
            setBody(req)
        }
        val body = response.bodyAsText()
        val root = json.parseToJsonElement(body)
        val element = (root as? JsonObject)?.let {
            it["pos_order"] ?: it["data"] ?: it
        } ?: root
        return json.decodeFromJsonElement(PosOrder.serializer(), element)
    }

    suspend fun getOrder(id: Long): PosOrder =
        json.decodeData(PosOrder.serializer()) { client.get(urls.posOrderById(id)) }

    suspend fun returnOrder(id: Long, items: List<PosOrderItemRequest>, reason: String? = null): PosOrder {
        val payload = buildJsonObject {
            put("items", json.encodeToJsonElement(ListSerializer(PosOrderItemRequest.serializer()), items))
            reason?.let { put("reason", it) }
        }
        return json.decodeData(PosOrder.serializer()) {
            client.post(urls.posOrderReturn(id)) {
                contentType(ContentType.Application.Json)
                setBody(payload)
            }
        }
    }
}
