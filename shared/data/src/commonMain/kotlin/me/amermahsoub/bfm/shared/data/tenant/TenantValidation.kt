package me.amermahsoub.bfm.shared.data.tenant

private val TENANT_SLUG_REGEX = Regex("^[a-z0-9-]{3,50}$")

fun isValidTenantSlug(slug: String): Boolean = TENANT_SLUG_REGEX.matches(slug)
