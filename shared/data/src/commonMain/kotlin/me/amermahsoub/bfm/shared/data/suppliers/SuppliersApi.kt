package me.amermahsoub.bfm.shared.data.suppliers

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

class SuppliersApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(page: Int = 1, search: String? = null): Paginated<Supplier> =
        json.decodePaginated(Supplier.serializer()) {
            client.get(urls.suppliers()) {
                parameter("page", page)
                search?.let { parameter("search", it) }
            }
        }

    suspend fun get(id: Long): Supplier =
        json.decodeData(Supplier.serializer()) {
            client.get(urls.supplierById(id))
        }

    suspend fun create(req: SupplierCreateRequest): Supplier =
        json.decodeData(Supplier.serializer()) {
            client.post(urls.suppliers()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun update(id: Long, req: SupplierCreateRequest): Supplier =
        json.decodeData(Supplier.serializer()) {
            client.put(urls.supplierById(id)) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun purchaseOrders(page: Int = 1): Paginated<PurchaseOrder> =
        json.decodePaginated(PurchaseOrder.serializer()) {
            client.get(urls.purchaseOrders()) {
                parameter("page", page)
            }
        }

    suspend fun getPurchaseOrder(id: Long): PurchaseOrder =
        json.decodeData(PurchaseOrder.serializer()) {
            client.get(urls.purchaseOrderById(id))
        }

    suspend fun createPurchaseOrder(req: PurchaseOrderCreateRequest): PurchaseOrder =
        json.decodeData(PurchaseOrder.serializer()) {
            client.post(urls.purchaseOrders()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }
}
