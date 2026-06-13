import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../domain/license_models.dart';
import '../licensing/license_codec.dart';
import '../licensing/license_constants.dart';
import 'license_repository.dart';

class LocalLicenseRepository implements LicenseRepository {
  LocalLicenseRepository({
    Directory? storageDirectory,
    LicenseTokenCodec? codec,
    DateTime Function()? now,
  }) : _storageDirectory = storageDirectory ?? _defaultStorageDirectory(),
       _codec =
           codec ?? LicenseTokenCodec(publicKeyBase64: kOperixLicensePublicKey),
       _now = now ?? (() => DateTime.now().toUtc());

  final Directory _storageDirectory;
  final LicenseTokenCodec _codec;
  final DateTime Function() _now;

  File get _installationFile =>
      File(_join(_storageDirectory.path, 'installation.json'));

  File get _licenseFile => File(_join(_storageDirectory.path, 'license.json'));

  @override
  Future<String> installationId() async {
    await _storageDirectory.create(recursive: true);
    if (await _installationFile.exists()) {
      try {
        final decoded = jsonDecode(await _installationFile.readAsString());
        if (decoded is Map && decoded['installationId'] is String) {
          final existing = (decoded['installationId'] as String).trim();
          if (existing.isNotEmpty) {
            return existing;
          }
        }
      } catch (_) {
        // Fall through and replace unreadable installation metadata.
      }
    }

    final generated = _generateInstallationId();
    await _installationFile.writeAsString(
      jsonEncode({
        'installationId': generated,
        'createdAt': _now().toIso8601String(),
      }),
    );
    return generated;
  }

  @override
  Future<LicenseValidationResult> loadLicense() async {
    final installId = await installationId();
    if (!await _licenseFile.exists()) {
      return LicenseValidationResult(
        status: LicenseStatus.missing,
        message: 'No Operix license is activated on this workstation.',
        installationId: installId,
      );
    }

    try {
      final decoded = jsonDecode(await _licenseFile.readAsString());
      final token = decoded is Map ? decoded['licenseKey']?.toString() : null;
      if (token == null || token.trim().isEmpty) {
        return LicenseValidationResult(
          status: LicenseStatus.invalid,
          message: 'Saved license file does not contain a license key.',
          installationId: installId,
        );
      }
      return _validateToken(token, installId: installId);
    } catch (error) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message: 'Saved license file could not be read: $error',
        installationId: installId,
      );
    }
  }

  @override
  Future<LicenseValidationResult> activate(String licenseKey) async {
    final installId = await installationId();
    final result = await _validateToken(licenseKey, installId: installId);
    if (!result.isValid) {
      return result;
    }

    await _storageDirectory.create(recursive: true);
    await _licenseFile.writeAsString(
      jsonEncode({
        'licenseKey': result.license!.token,
        'activatedAt': _now().toIso8601String(),
        'license': result.license!.toJson(),
      }),
    );
    return result;
  }

  Future<LicenseValidationResult> _validateToken(
    String token, {
    required String installId,
  }) async {
    final tokenValidation = await _codec.validate(token);
    if (!tokenValidation.isValid) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message: tokenValidation.message ?? 'License key is invalid.',
        installationId: installId,
      );
    }

    late final OperixLicense license;
    try {
      license = OperixLicense.fromPayload(
        tokenValidation.payload!,
        token: token.trim().replaceAll(RegExp(r'\s+'), ''),
      );
    } catch (error) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message: 'License payload is incomplete: $error',
        installationId: installId,
      );
    }

    if (license.product != kOperixLicenseProduct) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message: 'License is for ${license.product}, not Operix Desktop.',
        installationId: installId,
      );
    }

    if (license.installationId != installId) {
      return LicenseValidationResult(
        status: LicenseStatus.installationMismatch,
        message: 'License belongs to workstation ${license.installationId}.',
        installationId: installId,
      );
    }

    final now = _now();
    if (now.isBefore(license.validFrom.toUtc())) {
      return LicenseValidationResult(
        status: LicenseStatus.notYetActive,
        message: 'License is not active until ${license.validFrom.toLocal()}.',
        installationId: installId,
      );
    }
    if (now.isAfter(license.expiresAt.toUtc())) {
      return LicenseValidationResult(
        status: LicenseStatus.expired,
        message: 'License expired on ${license.expiresAt.toLocal()}.',
        installationId: installId,
        license: license,
      );
    }

    return LicenseValidationResult(
      status: LicenseStatus.valid,
      message: 'License is active for ${license.businessName}.',
      installationId: installId,
      license: license,
    );
  }

  String _generateInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(15, (_) => random.nextInt(256));
    final raw = base64UrlEncode(bytes).replaceAll('=', '').toUpperCase();
    final groups = <String>[];
    for (var i = 0; i < raw.length; i += 4) {
      groups.add(raw.substring(i, min(i + 4, raw.length)));
    }
    return 'OPX-${groups.join('-')}';
  }

  static Directory _defaultStorageDirectory() {
    if (Platform.isWindows) {
      final base =
          Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          Directory.current.path;
      return Directory(_join(base, 'Operix'));
    }

    final home = Platform.environment['HOME'] ?? Directory.current.path;
    if (Platform.isMacOS) {
      return Directory(
        _join(_join(_join(home, 'Library'), 'Application Support'), 'Operix'),
      );
    }

    final configHome =
        Platform.environment['XDG_CONFIG_HOME'] ?? _join(home, '.config');
    return Directory(_join(configHome, 'operix'));
  }

  static String _join(String left, String right) {
    if (left.endsWith(Platform.pathSeparator)) {
      return '$left$right';
    }
    return '$left${Platform.pathSeparator}$right';
  }
}
