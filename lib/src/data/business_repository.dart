import '../domain/business_profile.dart';

abstract interface class BusinessRepository {
  Future<BusinessProfile?> loadProfile();

  Future<bool> hasProfile();

  Future<BusinessProfile> saveProfile(BusinessProfile profile);
}
