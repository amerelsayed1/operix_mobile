import 'dart:io';

import 'package:operix_mobile/src/licensing/license_codec.dart';
import 'package:operix_mobile/src/licensing/license_constants.dart';

const _developmentPrivateSeedBase64 =
    'bRwVqlm0VJrZkMsS8AiNDXEPybJPv1D_38KFI4J6z6I';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    return;
  }

  switch (args.first) {
    case 'generate-keypair':
      final pair = await LicenseTokenCodec.generateKeyPair();
      stdout.writeln('Private seed base64: ${pair.privateSeedBase64}');
      stdout.writeln('Public key base64:   ${pair.publicKeyBase64}');
      stdout.writeln('');
      stdout.writeln(
        'Keep the private seed outside release builds. Put only the public key '
        'in lib/src/licensing/license_constants.dart.',
      );
      return;
    case 'create':
      await _create(args.skip(1).toList());
      return;
    default:
      stderr.writeln('Unknown command: ${args.first}');
      _printUsage();
      exitCode = 64;
  }
}

Future<void> _create(List<String> args) async {
  final values = _parseArgs(args);
  final business = values['business'] ?? values['name'];
  final installationId = values['installation'] ?? values['install-id'];
  if (business == null || business.trim().isEmpty) {
    stderr.writeln('Missing --business "Business Name"');
    exitCode = 64;
    return;
  }
  if (installationId == null || installationId.trim().isEmpty) {
    stderr.writeln('Missing --installation OPX-...');
    exitCode = 64;
    return;
  }

  final privateSeed =
      values['private-key'] ??
      Platform.environment['OPERIX_LICENSE_PRIVATE_KEY'] ??
      _developmentPrivateSeedBase64;

  if (privateSeed == _developmentPrivateSeedBase64) {
    stderr.writeln(
      'Using the bundled development signing key. Replace it before release.',
    );
  }

  final now = DateTime.now().toUtc();
  final days = int.tryParse(values['days'] ?? '') ?? 365;
  final licenseId = values['license-id'] ?? _buildLicenseId(now);
  final modules =
      (values['modules'] ??
              'pos,inventory,sales,purchases,clients,suppliers,accounting')
          .split(',')
          .map((module) => module.trim())
          .where((module) => module.isNotEmpty)
          .toList(growable: false);

  final payload = <String, Object?>{
    'v': 1,
    'licenseId': licenseId,
    'product': kOperixLicenseProduct,
    'businessName': business.trim(),
    'installationId': installationId.trim(),
    'plan': values['plan'] ?? 'desktop-local',
    'maxDevices': int.tryParse(values['devices'] ?? '') ?? 1,
    'modules': modules,
    'issuedAt': now.toIso8601String(),
    'validFrom': (DateTime.tryParse(values['valid-from'] ?? '')?.toUtc() ?? now)
        .toIso8601String(),
    'expiresAt': now.add(Duration(days: days)).toIso8601String(),
  };

  final token = await LicenseTokenCodec.signPayload(
    payload: payload,
    privateSeedBase64: privateSeed,
  );

  final output = values['output'];
  if (output == null || output.trim().isEmpty) {
    stdout.writeln(token);
  } else {
    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsString('$token\n');
    stdout.writeln('License written to ${file.path}');
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final values = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) {
      continue;
    }
    final keyValue = arg.substring(2).split('=');
    if (keyValue.length == 2) {
      values[keyValue.first] = keyValue.last;
      continue;
    }
    if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      values[keyValue.first] = args[++i];
    } else {
      values[keyValue.first] = 'true';
    }
  }
  return values;
}

String _buildLicenseId(DateTime now) {
  final millis = now.millisecondsSinceEpoch.toRadixString(36).toUpperCase();
  return 'OPX-LIC-$millis';
}

void _printUsage() {
  stdout.writeln('''
Operix license tool

Commands:
  dart run tool/license_tool.dart generate-keypair
  dart run tool/license_tool.dart create --business "Style Shop" --installation OPX-...

Create options:
  --business       Licensed business name
  --installation   Workstation installation id shown on activation screen
  --days           Validity period in days, default 365
  --modules        Comma-separated modules, default all local modules
  --devices        Max devices, default 1
  --plan           License plan label, default desktop-local
  --private-key    Ed25519 private seed base64. Also read from OPERIX_LICENSE_PRIVATE_KEY.
  --output         File to write the license token
''');
}
