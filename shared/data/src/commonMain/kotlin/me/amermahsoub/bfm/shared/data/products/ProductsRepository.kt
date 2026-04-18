package me.amermahsoub.bfm.shared.data.products

class ProductsRepository(private val api: ProductsApi) {
    suspend fun list(search: String? = null, categoryId: Long? = null, page: Int = 1) =
        api.list(search = search, categoryId = categoryId, page = page)

    suspend fun get(id: Long) = api.get(id)
    suspend fun categories() = api.categories()
    suspend fun transactions(id: Long) = api.transactions(id)
}
