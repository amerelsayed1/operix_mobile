package me.amermahsoub.bfm.shared.data.profile

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder

@Serializable
data class ProfileInfo(
    val id: Long,
    val name: String,
    val email: String? = null,
    val phone: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    val locale: String? = null,
    val role: String? = null,
)

@Serializable
data class UpdateProfileRequest(
    val name: String,
    val email: String? = null,
    val phone: String? = null,
    val locale: String? = null,
)

@Serializable
data class ChangePasswordRequest(
    @SerialName("current_password") val currentPassword: String,
    val password: String,
    @SerialName("password_confirmation") val passwordConfirmation: String,
)

class ProfileApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun get(): ProfileInfo =
        json.decodeData(ProfileInfo.serializer()) { client.get(urls.profile()) }

    suspend fun update(req: UpdateProfileRequest): ProfileInfo =
        json.decodeData(ProfileInfo.serializer()) {
            client.put(urls.profile()) {
                contentType(ContentType.Application.Json)
                setBody(req)
            }
        }

    suspend fun changePassword(req: ChangePasswordRequest) {
        client.put(urls.profilePassword()) {
            contentType(ContentType.Application.Json)
            setBody(req)
        }
    }
}
