package me.amermahsoub.bfm.shared.data.common

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class DataEnvelope<T>(
    val data: T? = null,
    val message: String? = null,
    val success: Boolean? = null,
)

@Serializable
data class PaginatedEnvelope<T>(
    val data: List<T> = emptyList(),
    val meta: PaginationMeta? = null,
)

@Serializable
data class PaginationMeta(
    @SerialName("current_page") val currentPage: Int = 1,
    @SerialName("last_page") val lastPage: Int = 1,
    @SerialName("per_page") val perPage: Int = 15,
    val total: Int = 0,
)

@Serializable
data class ValidationErrorBody(
    val message: String? = null,
    val errors: Map<String, List<String>> = emptyMap(),
)
