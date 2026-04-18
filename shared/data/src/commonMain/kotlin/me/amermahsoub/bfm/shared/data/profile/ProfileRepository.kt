package me.amermahsoub.bfm.shared.data.profile

class ProfileRepository(private val api: ProfileApi) {
    suspend fun get() = api.get()
    suspend fun update(req: UpdateProfileRequest) = api.update(req)
    suspend fun changePassword(req: ChangePasswordRequest) = api.changePassword(req)
}
