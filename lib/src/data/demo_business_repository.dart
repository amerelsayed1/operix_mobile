import '../domain/business_profile.dart';
import 'business_repository.dart';

class DemoBusinessRepository implements BusinessRepository {
  DemoBusinessRepository({BusinessProfile? initialProfile})
    : _profile = initialProfile;

  BusinessProfile? _profile;

  @override
  Future<BusinessProfile?> loadProfile() async => _profile;

  @override
  Future<bool> hasProfile() async => _profile != null;

  @override
  Future<BusinessProfile> saveProfile(BusinessProfile profile) async {
    _profile = profile;
    return profile;
  }
}
