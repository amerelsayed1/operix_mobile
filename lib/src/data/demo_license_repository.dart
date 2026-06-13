import '../domain/license_models.dart';
import '../licensing/license_constants.dart';
import 'license_repository.dart';

class DemoLicenseRepository implements LicenseRepository {
  DemoLicenseRepository({
    this.installation = 'OPX-TEST-WORK-STATION',
    DateTime? expiresAt,
  }) : _expiresAt = expiresAt ?? DateTime.utc(2099, 12, 31);

  final String installation;
  final DateTime _expiresAt;

  @override
  Future<String> installationId() async => installation;

  @override
  Future<LicenseValidationResult> loadLicense() async {
    return _valid('Demo license is active.');
  }

  @override
  Future<LicenseValidationResult> activate(String licenseKey) async {
    if (licenseKey.trim().isEmpty) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message: 'Enter a license key.',
        installationId: installation,
      );
    }
    return _valid('Demo license accepted.');
  }

  LicenseValidationResult _valid(String message) {
    return LicenseValidationResult(
      status: LicenseStatus.valid,
      message: message,
      installationId: installation,
      license: OperixLicense(
        licenseId: 'OPX-DEMO',
        businessName: 'Demo Business',
        installationId: installation,
        product: kOperixLicenseProduct,
        plan: 'desktop-local',
        issuedAt: DateTime.utc(2026, 1),
        validFrom: DateTime.utc(2026, 1),
        expiresAt: _expiresAt,
        maxDevices: 1,
        modules: const [
          'pos',
          'inventory',
          'sales',
          'purchases',
          'clients',
          'suppliers',
          'accounting',
        ],
        token: 'demo',
      ),
    );
  }
}
