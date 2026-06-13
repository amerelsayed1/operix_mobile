import '../domain/license_models.dart';

abstract interface class LicenseRepository {
  Future<String> installationId();

  Future<LicenseValidationResult> loadLicense();

  Future<LicenseValidationResult> activate(String licenseKey);
}
