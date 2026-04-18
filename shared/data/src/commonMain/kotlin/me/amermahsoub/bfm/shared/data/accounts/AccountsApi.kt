package me.amermahsoub.bfm.shared.data.accounts

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
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
data class Account(
    val id: Long,
    val name: String,
    val type: String? = null,
    @SerialName("current_balance") val currentBalance: String? = null,
    @SerialName("opening_balance") val openingBalance: String? = null,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("is_drawer") val isDrawer: Boolean = false,
)

@Serializable
data class AccountHistoryEntry(
    val id: Long,
    val type: String,
    val amount: String,
    @SerialName("balance_after") val balanceAfter: String? = null,
    val reference: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class DepositRequest(
    @SerialName("account_id") val accountId: Long,
    val amount: String,
    val notes: String? = null,
    @SerialName("payment_method_id") val paymentMethodId: Long? = null,
)

@Serializable
data class WithdrawRequest(
    @SerialName("account_id") val accountId: Long,
    val amount: String,
    val notes: String? = null,
)

@Serializable
data class TransferRequest(
    @SerialName("from_account_id") val fromAccountId: Long,
    @SerialName("to_account_id") val toAccountId: Long,
    val amount: String,
    val notes: String? = null,
)

class AccountsApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(): List<Account> =
        json.decodeData(ListSerializer(Account.serializer())) { client.get(urls.accounts()) }

    suspend fun get(id: Long): Account =
        json.decodeData(Account.serializer()) { client.get(urls.accountById(id)) }

    suspend fun history(id: Long, page: Int = 1, perPage: Int = 20): Paginated<AccountHistoryEntry> =
        json.decodePaginated(AccountHistoryEntry.serializer()) {
            client.get(urls.accountHistory(id)) {
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun deposit(req: DepositRequest): Account =
        json.decodeData(Account.serializer()) {
            client.post(urls.accountDeposit()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun withdraw(req: WithdrawRequest): Account =
        json.decodeData(Account.serializer()) {
            client.post(urls.accountWithdraw()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun transfer(req: TransferRequest): Account =
        json.decodeData(Account.serializer()) {
            client.post(urls.accountTransfer()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }
}
