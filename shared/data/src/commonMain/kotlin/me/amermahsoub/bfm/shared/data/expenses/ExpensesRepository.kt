package me.amermahsoub.bfm.shared.data.expenses

class ExpensesRepository(private val api: ExpensesApi) {
    suspend fun list(categoryId: Long? = null, fromDate: String? = null, toDate: String? = null, page: Int = 1) =
        api.list(categoryId = categoryId, fromDate = fromDate, toDate = toDate, page = page)

    suspend fun get(id: Long) = api.get(id)
    suspend fun create(req: ExpenseCreateRequest) = api.create(req)
    suspend fun update(id: Long, req: ExpenseCreateRequest) = api.update(id, req)
    suspend fun delete(id: Long) = api.delete(id)
    suspend fun categories() = api.categories()
}
