package me.amermahsoub.bfm.shared.data.invoices

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

class InvoicesApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(page: Int = 1, status: String? = null): Paginated<Invoice> =
        json.decodePaginated(Invoice.serializer()) {
            client.get(urls.invoices()) {
                parameter("page", page)
                status?.let { parameter("status", it) }
            }
        }

    suspend fun get(id: Long): Invoice =
        json.decodeData(Invoice.serializer()) {
            client.get(urls.invoiceById(id))
        }

    suspend fun createFromOrder(req: InvoiceCreateRequest): Invoice =
        json.decodeData(Invoice.serializer()) {
            client.post(urls.invoices()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }
}
