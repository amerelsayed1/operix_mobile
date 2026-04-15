package me.amermahsoub.bfm.shared.data.clients

class ClientsRepository(private val api: ClientsApi) {
    suspend fun list(search: String? = null, status: String? = null, page: Int = 1) =
        api.list(search = search, status = status, page = page)

    suspend fun summary() = api.summary()
    suspend fun get(id: Long) = api.get(id)
    suspend fun create(req: ClientCreateRequest) = api.create(req)
    suspend fun update(id: Long, req: ClientCreateRequest) = api.update(id, req)
    suspend fun delete(id: Long) = api.delete(id)
    suspend fun payments(id: Long) = api.payments(id)
    suspend fun recordPayment(id: Long, req: ClientPaymentRequest) = api.recordPayment(id, req)
    suspend fun block(id: Long, reason: String? = null) = api.block(id, reason)
    suspend fun unblock(id: Long) = api.unblock(id)
    suspend fun updateCredit(id: Long, creditLimit: String) = api.updateCredit(id, creditLimit)
}
