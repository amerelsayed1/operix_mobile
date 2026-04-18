package me.amermahsoub.bfm.shared.data.expenses

import io.ktor.client.HttpClient
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

@Serializable
data class Expense(
    val id: Long,
    @SerialName("account_id") val accountId: Long? = null,
    @SerialName("account_name") val accountName: String? = null,
    @SerialName("category_id") val categoryId: Long? = null,
    @SerialName("category_name") val categoryName: String? = null,
    val amount: String,
    val date: String? = null,
    val description: String? = null,
    @SerialName("is_ads") val isAds: Boolean = false,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class ExpenseCategory(
    val id: Long,
    val name: String,
)

@Serializable
data class ExpenseCreateRequest(
    @SerialName("account_id") val accountId: Long,
    @SerialName("category_id") val categoryId: Long? = null,
    val amount: String,
    val date: String,
    val description: String? = null,
    @SerialName("is_ads") val isAds: Boolean = false,
)

class ExpensesApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(
        categoryId: Long? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): Paginated<Expense> =
        json.decodePaginated(Expense.serializer()) {
            client.get(urls.expenses()) {
                categoryId?.let { parameter("category_id", it) }
                fromDate?.let { parameter("from_date", it) }
                toDate?.let { parameter("to_date", it) }
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun get(id: Long): Expense =
        json.decodeData(Expense.serializer()) { client.get(urls.expenseById(id)) }

    suspend fun create(req: ExpenseCreateRequest): Expense =
        json.decodeData(Expense.serializer()) {
            client.post(urls.expenses()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun update(id: Long, req: ExpenseCreateRequest): Expense =
        json.decodeData(Expense.serializer()) {
            client.put(urls.expenseById(id)) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun delete(id: Long) {
        client.delete(urls.expenseById(id))
    }

    suspend fun categories(): List<ExpenseCategory> =
        json.decodeData(ListSerializer(ExpenseCategory.serializer())) {
            client.get(urls.expenseCategories())
        }
}
