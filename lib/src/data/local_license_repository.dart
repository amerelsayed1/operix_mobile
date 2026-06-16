import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

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

  /// Tracks the highest wall-clock time we've ever observed, so setting the OS
  /// clock backwards can't revive an expired license (offline anti-rollback).
  File get _stateFile =>
      File(_join(_storageDirectory.path, 'license_state.json'));

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

  /// The highest UTC time we've recorded, or null if none yet.
  Future<DateTime?> _readLastSeen() async {
    try {
      if (!await _stateFile.exists()) return null;
      final decoded = jsonDecode(await _stateFile.readAsString());
      if (decoded is Map && decoded['lastSeenAt'] is String) {
        return DateTime.tryParse(decoded['lastSeenAt'] as String)?.toUtc();
      }
    } catch (_) {
      // Treat unreadable state as "no record" — fail safe, not closed.
    }
    return null;
  }

  Future<void> _writeLastSeen(DateTime value) async {
    try {
      await _storageDirectory.create(recursive: true);
      await _stateFile.writeAsString(
        jsonEncode({'lastSeenAt': value.toUtc().toIso8601String()}),
      );
    } catch (_) {
      // Best-effort; a failed write just means we don't advance the watermark.
    }
  }

  Future<LicenseValidationResult> _validateToken(
    String token, {
    required String installId,
  }) async {
    // Fail closed in release builds still verifying with the insecure dev key —
    // its private seed is public, so any license would be forgeable.
    if (kReleaseMode && isUsingDevLicenseKey) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message:
            'This build is not configured with a production license key. '
            'Rebuild with --dart-define=OPERIX_LICENSE_PUBLIC_KEY=<key>.',
        installationId: installId,
      );
    }

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
    final lastSeen = await _readLastSeen();

    // Anti-rollback: if the clock has been moved meaningfully behind the highest
    // time we've ever recorded, refuse to validate rather than let a rolled-back
    // clock revive an expired license. A small tolerance absorbs normal drift.
    const rollbackTolerance = Duration(minutes: 5);
    if (lastSeen != null &&
        now.isBefore(lastSeen.subtract(rollbackTolerance))) {
      return LicenseValidationResult(
        status: LicenseStatus.invalid,
        message:
            'The system clock appears to have been set backwards. Restore the '
            'correct date and time to continue using Operix.',
        installationId: installId,
        license: license,
      );
    }

    // Evaluate expiry against the furthest-forward time we trust, so a small
    // (within-tolerance) rollback still can't un-expire a license.
    final effectiveNow = (lastSeen != null && lastSeen.isAfter(now))
        ? lastSeen
        : now;

    // Advance the watermark before returning (only ever moves forward).
    if (lastSeen == null || now.isAfter(lastSeen)) {
      await _writeLastSeen(now);
    }

    if (effectiveNow.isBefore(license.validFrom.toUtc())) {
      return LicenseValidationResult(
        status: LicenseStatus.notYetActive,
        message: 'License is not active until ${license.validFrom.toLocal()}.',
        installationId: installId,
      );
    }
    if (effectiveNow.isAfter(license.expiresAt.toUtc())) {
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
