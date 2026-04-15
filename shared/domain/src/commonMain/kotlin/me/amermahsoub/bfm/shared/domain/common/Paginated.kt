package me.amermahsoub.bfm.shared.domain.common

/**
 * Matches the Laravel pagination envelope.
 */
data class Paginated<T>(
    val data: List<T>,
    val currentPage: Int,
    val lastPage: Int,
    val perPage: Int,
    val total: Int,
) {
    val hasMore: Boolean get() = currentPage < lastPage

    companion object {
        fun <T> empty(): Paginated<T> = Paginated(emptyList(), 1, 1, 15, 0)
    }
}
