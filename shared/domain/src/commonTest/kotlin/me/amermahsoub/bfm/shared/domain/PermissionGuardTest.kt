package me.amermahsoub.bfm.shared.domain

import me.amermahsoub.bfm.shared.domain.permissions.PermissionGuard
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PermissionGuardTest {

    @Test
    fun has_existingPermission_returnsTrue() {
        val guard = PermissionGuard.of(listOf("pos.view", "pos.create"))
        assertTrue(guard.has("pos.view"))
    }

    @Test
    fun has_missingPermission_returnsFalse() {
        val guard = PermissionGuard.of(listOf("pos.view"))
        assertFalse(guard.has("pos.delete"))
    }

    @Test
    fun has_adminWildcard_grantsEverything() {
        val guard = PermissionGuard.of(listOf("*"))
        assertTrue(guard.has("pos.view"))
        assertTrue(guard.has("sales.create"))
        assertTrue(guard.has("anything.at.all"))
    }

    @Test
    fun hasAny_withMatch_returnsTrue() {
        val guard = PermissionGuard.of(listOf("pos.view", "sales.view"))
        assertTrue(guard.hasAny("pos.view", "clients.view"))
    }

    @Test
    fun hasAny_withNoMatch_returnsFalse() {
        val guard = PermissionGuard.of(listOf("pos.view"))
        assertFalse(guard.hasAny("sales.view", "clients.view"))
    }

    @Test
    fun hasAny_adminWildcard_returnsTrue() {
        val guard = PermissionGuard.of(listOf("*"))
        assertTrue(guard.hasAny("anything", "something.else"))
    }

    @Test
    fun hasAll_allPresent_returnsTrue() {
        val guard = PermissionGuard.of(listOf("pos.view", "pos.create", "pos.update"))
        assertTrue(guard.hasAll("pos.view", "pos.create"))
    }

    @Test
    fun hasAll_partialMatch_returnsFalse() {
        val guard = PermissionGuard.of(listOf("pos.view"))
        assertFalse(guard.hasAll("pos.view", "pos.create"))
    }

    @Test
    fun hasAll_adminWildcard_returnsTrue() {
        val guard = PermissionGuard.of(listOf("*"))
        assertTrue(guard.hasAll("pos.view", "pos.create", "pos.delete"))
    }

    @Test
    fun isAdmin_withWildcard_returnsTrue() {
        val guard = PermissionGuard.of(listOf("*"))
        assertTrue(guard.isAdmin)
    }

    @Test
    fun isAdmin_withoutWildcard_returnsFalse() {
        val guard = PermissionGuard.of(listOf("pos.view", "sales.view"))
        assertFalse(guard.isAdmin)
    }

    @Test
    fun isAdmin_emptyGuard_returnsFalse() {
        assertFalse(PermissionGuard.Empty.isAdmin)
    }

    @Test
    fun empty_hasNothing() {
        val guard = PermissionGuard.Empty
        assertFalse(guard.has("pos.view"))
        assertFalse(guard.hasAny("pos.view", "sales.view"))
        assertFalse(guard.hasAll("pos.view"))
        assertFalse(guard.isAdmin)
    }

    @Test
    fun of_createsGuardFromList() {
        val guard = PermissionGuard.of(listOf("pos.view", "pos.create"))
        assertTrue(guard.has("pos.view"))
        assertTrue(guard.has("pos.create"))
        assertFalse(guard.has("pos.delete"))
    }

    @Test
    fun of_deduplicatesList() {
        val guard = PermissionGuard.of(listOf("pos.view", "pos.view", "pos.view"))
        assertTrue(guard.has("pos.view"))
    }
}
