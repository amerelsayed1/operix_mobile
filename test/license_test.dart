import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:operix_mobile/src/data/local_license_repository.dart';
import 'package:operix_mobile/src/domain/license_models.dart';
import 'package:operix_mobile/src/licensing/license_codec.dart';
import 'package:operix_mobile/src/licensing/license_constants.dart';

void main() {
  test('signs, activates, stores, and reloads a local license', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'operix_license_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final keyPair = await LicenseTokenCodec.generateKeyPair();
    final codec = LicenseTokenCodec(publicKeyBase64: keyPair.publicKeyBase64);
    final now = DateTime.utc(2026, 6, 13, 10);
    final repository = LocalLicenseRepository(
      storageDirectory: tempDir,
      codec: codec,
      now: () => now,
    );

    final installationId = await repository.installationId();
    final token = await LicenseTokenCodec.signPayload(
      privateSeedBase64: keyPair.privateSeedBase64,
      payload: {
        'v': 1,
        'licenseId': 'OPX-LIC-TEST',
        'product': kOperixLicenseProduct,
        'businessName': 'Style Shop',
        'installationId': installationId,
        'plan': 'desktop-local',
        'maxDevices': 1,
        'modules': ['pos', 'inventory'],
        'issuedAt': now.toIso8601String(),
        'validFrom': now.toIso8601String(),
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
      },
    );

    final activated = await repository.activate(token);
    expect(activated.status, LicenseStatus.valid);
    expect(activated.license?.businessName, 'Style Shop');

    final reloaded = await repository.loadLicense();
    expect(reloaded.status, LicenseStatus.valid);
    expect(reloaded.license?.licenseId, 'OPX-LIC-TEST');
  });
}
