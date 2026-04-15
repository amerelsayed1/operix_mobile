package me.amermahsoub.bfm.shared.data.accounts

class AccountsRepository(private val api: AccountsApi) {
    suspend fun list() = api.list()
    suspend fun get(id: Long) = api.get(id)
    suspend fun history(id: Long, page: Int = 1) = api.history(id, page)
    suspend fun deposit(req: DepositRequest) = api.deposit(req)
    suspend fun withdraw(req: WithdrawRequest) = api.withdraw(req)
    suspend fun transfer(req: TransferRequest) = api.transfer(req)
}
