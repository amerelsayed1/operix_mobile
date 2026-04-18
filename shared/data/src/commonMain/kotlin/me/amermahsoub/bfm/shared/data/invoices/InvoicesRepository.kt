package me.amermahsoub.bfm.shared.data.invoices

import me.amermahsoub.bfm.shared.domain.common.Paginated

class InvoicesRepository(private val api: InvoicesApi) {
    suspend fun list(page: Int = 1, status: String? = null): Paginated<Invoice> = api.list(page, status)
    suspend fun get(id: Long): Invoice = api.get(id)
    suspend fun createFromOrder(req: InvoiceCreateRequest): Invoice = api.createFromOrder(req)
}
