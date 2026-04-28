package me.amermahsoub.bfm.shared.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PaginationMeta(
    @SerialName("current_page") val currentPage: Int = 1,
    @SerialName("last_page") val lastPage: Int = 1,
    val total: Int = 0,
    @SerialName("per_page") val perPage: Int = 15,
)

@Serializable
data class ApiResponse<T>(
    val data: T? = null,
    val message: String? = null,
    val status: Boolean = true,
)

@Serializable
data class PaginatedResponse<T>(
    val data: List<T> = emptyList(),
    val meta: PaginationMeta? = null,
    val message: String? = null,
)

sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val message: String, val code: Int = 0) : Result<Nothing>()
    data object Loading : Result<Nothing>()
}

fun <T> Result<T>.getOrNull(): T? = if (this is Result.Success) data else null
fun <T> Result<T>.isSuccess(): Boolean = this is Result.Success
fun <T> Result<T>.isLoading(): Boolean = this is Result.Loading
