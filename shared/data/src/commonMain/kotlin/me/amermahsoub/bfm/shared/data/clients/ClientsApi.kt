package me.amermahsoub.bfm.shared.data.clients

import io.ktor.client.HttpClient
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.patch
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

@Serializable
data class Client(
    val id: Long,
    val name: String,
    val phone: String? = null,
    val email: String? = null,
    val address: String? = null,
    val balance: String? = null,
    @SerialName("credit_limit") val creditLimit: String? = null,
    val status: String? = null,
    @SerialName("blocked_at") val blockedAt: String? = null,
    @SerialName("is_tax_exempt") val isTaxExempt: Boolean = false,
    @SerialName("total_orders") val totalOrders: Int? = null,
    @SerialName("total_due") val totalDue: String? = null,
    @SerialName("last_order_date") val lastOrderDate: String? = null,
    val notes: String? = null,
) {
    val isBlocked: Boolean get() = status?.equals("blocked", ignoreCase = true) == true || blockedAt != null
}

@Serializable
data class ClientsSummary(
    @SerialName("total_clients") val totalClients: Int? = null,
    @SerialName("active_clients") val activeClients: Int? = null,
    @SerialName("blocked_clients") val blockedClients: Int? = null,
    @SerialName("total_receivables") val totalReceivables: String? = null,
    @SerialName("overdue_amount") val overdueAmount: String? = null,
)

@Serializable
data class ClientCreateRequest(
    val name: String,
    val phone: String? = null,
    val email: String? = null,
    val address: String? = null,
    @SerialName("credit_limit") val creditLimit: String? = null,
    val status: String = "active",
    val notes: String? = null,
)

@Serializable
data class ClientPayment(
    val id: Long,
    @SerialName("client_id") val clientId: Long? = null,
    val reference: String? = null,
    val amount: String,
    @SerialName("payment_date") val paymentDate: String? = null,
    @SerialName("payment_method_id") val paymentMethodId: Long? = null,
    @SerialName("account_id") val accountId: Long? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class ClientPaymentRequest(
    val amount: String,
    @SerialName("payment_method_id") val paymentMethodId: Long? = null,
    @SerialName("account_id") val accountId: Long? = null,
    @SerialName("payment_date") val paymentDate: String? = null,
    val notes: String? = null,
)

class ClientsApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(
        search: String? = null,
        status: String? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): Paginated<Client> =
        json.decodePaginated(Client.serializer()) {
            client.get(urls.clients()) {
                search?.let { parameter("search", it) }
                status?.let { parameter("status", it) }
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun get(id: Long): Client =
        json.decodeData(Client.serializer()) { client.get(urls.clientById(id)) }

    suspend fun create(req: ClientCreateRequest): Client =
        json.decodeData(Client.serializer()) {
            client.post(urls.clients()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun update(id: Long, req: ClientCreateRequest): Client =
        json.decodeData(Client.serializer()) {
            client.put(urls.clientById(id)) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun delete(id: Long) {
        client.delete(urls.clientById(id))
    }

    suspend fun summary(): ClientsSummary =
        json.decodeData(ClientsSummary.serializer()) { client.get(urls.clientsSummary()) }

    suspend fun payments(clientId: Long): List<ClientPayment> =
        json.decodeData(ListSerializer(ClientPayment.serializer())) {
            client.get(urls.clientPayments(clientId))
        }

    suspend fun recordPayment(clientId: Long, req: ClientPaymentRequest): ClientPayment =
        json.decodeData(ClientPayment.serializer()) {
            client.post(urls.clientRecordPayment(clientId)) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun block(clientId: Long, reason: String? = null): Client {
        val payload = buildJsonObject {
            if (reason != null) put("reason", reason) else put("reason", JsonNull)
        }
        return json.decodeData(Client.serializer()) {
            client.post(urls.clientBlock(clientId)) {
                contentType(ContentType.Application.Json)
                setBody(payload)
            }
        }
    }

    suspend fun unblock(clientId: Long): Client =
        json.decodeData(Client.serializer()) { client.post(urls.clientUnblock(clientId)) }

    suspend fun updateCredit(clientId: Long, creditLimit: String): Client {
        val payload = buildJsonObject { put("credit_limit", creditLimit) }
        return json.decodeData(Client.serializer()) {
            client.patch(urls.clientCredit(clientId)) {
                contentType(ContentType.Application.Json)
                setBody(payload)
            }
        }
    }
}
