enum LicenseStatus {
  missing,
  valid,
  invalid,
  expired,
  notYetActive,
  installationMismatch,
}

class OperixLicense {
  const OperixLicense({
    required this.licenseId,
    required this.businessName,
    required this.installationId,
    required this.product,
    required this.plan,
    required this.issuedAt,
    required this.validFrom,
    required this.expiresAt,
    required this.maxDevices,
    required this.modules,
    required this.token,
  });

  final String licenseId;
  final String businessName;
  final String installationId;
  final String product;
  final String plan;
  final DateTime issuedAt;
  final DateTime validFrom;
  final DateTime expiresAt;
  final int maxDevices;
  final List<String> modules;
  final String token;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  int get daysRemaining {
    final remaining = expiresAt
        .toUtc()
        .difference(DateTime.now().toUtc())
        .inDays;
    return remaining < 0 ? 0 : remaining;
  }

  Map<String, Object?> toJson() {
    return {
      'licenseId': licenseId,
      'businessName': businessName,
      'installationId': installationId,
      'product': product,
      'plan': plan,
      'issuedAt': issuedAt.toUtc().toIso8601String(),
      'validFrom': validFrom.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'maxDevices': maxDevices,
      'modules': modules,
    };
  }

  static OperixLicense fromPayload(
    Map<String, Object?> payload, {
    required String token,
  }) {
    return OperixLicense(
      licenseId: _string(payload['licenseId']),
      businessName: _string(payload['businessName']),
      installationId: _string(payload['installationId']),
      product: _string(payload['product']),
      plan: _string(payload['plan']),
      issuedAt: _date(payload['issuedAt']),
      validFrom: _date(payload['validFrom']),
      expiresAt: _date(payload['expiresAt']),
      maxDevices: _int(payload['maxDevices'], fallback: 1),
      modules: _stringList(payload['modules']),
      token: token,
    );
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime _date(Object? value) {
    return DateTime.parse(value?.toString() ?? '').toUtc();
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

class LicenseValidationResult {
  const LicenseValidationResult({
    required this.status,
    required this.message,
    required this.installationId,
    this.license,
  });

  final LicenseStatus status;
  final String message;
  final String installationId;
  final OperixLicense? license;

  bool get isValid => status == LicenseStatus.valid && license != null;
}
