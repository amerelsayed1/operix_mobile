import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class LicenseTokenValidation {
  const LicenseTokenValidation.valid(this.payload) : message = null;

  const LicenseTokenValidation.invalid(this.message) : payload = null;

  final Map<String, Object?>? payload;
  final String? message;

  bool get isValid => payload != null;
}

class GeneratedLicenseKeyPair {
  const GeneratedLicenseKeyPair({
    required this.privateSeedBase64,
    required this.publicKeyBase64,
  });

  final String privateSeedBase64;
  final String publicKeyBase64;
}

class LicenseTokenCodec {
  LicenseTokenCodec({required this.publicKeyBase64});

  static const prefix = 'OPX1';

  final String publicKeyBase64;
  final Ed25519 _algorithm = Ed25519();

  Future<LicenseTokenValidation> validate(String token) async {
    final normalized = token.trim().replaceAll(RegExp(r'\s+'), '');
    final parts = normalized.split('.');

    if (parts.length != 3 || parts.first != prefix) {
      return const LicenseTokenValidation.invalid(
        'License key must start with OPX1 and contain a signed payload.',
      );
    }

    try {
      final payloadBytes = _decodeBase64Url(parts[1]);
      final signatureBytes = _decodeBase64Url(parts[2]);
      final publicKey = SimplePublicKey(
        _decodeBase64Url(publicKeyBase64),
        type: KeyPairType.ed25519,
      );
      final verified = await _algorithm.verify(
        payloadBytes,
        signature: Signature(signatureBytes, publicKey: publicKey),
      );

      if (!verified) {
        return const LicenseTokenValidation.invalid(
          'License signature is not valid for this Operix build.',
        );
      }

      final decoded = jsonDecode(utf8.decode(payloadBytes));
      if (decoded is! Map<String, Object?>) {
        return const LicenseTokenValidation.invalid(
          'License payload is not a valid object.',
        );
      }
      return LicenseTokenValidation.valid(decoded);
    } catch (error) {
      return LicenseTokenValidation.invalid(
        'License could not be read: $error',
      );
    }
  }

  static Future<GeneratedLicenseKeyPair> generateKeyPair() async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final privateData = await keyPair.extract();
    final publicKey = await keyPair.extractPublicKey();
    return GeneratedLicenseKeyPair(
      privateSeedBase64: _encodeBase64Url(privateData.bytes),
      publicKeyBase64: _encodeBase64Url(publicKey.bytes),
    );
  }

  static Future<String> publicKeyFromPrivateSeed(
    String privateSeedBase64,
  ) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(
      _decodeBase64Url(privateSeedBase64),
    );
    final publicKey = await keyPair.extractPublicKey();
    return _encodeBase64Url(publicKey.bytes);
  }

  static Future<String> signPayload({
    required Map<String, Object?> payload,
    required String privateSeedBase64,
  }) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(
      _decodeBase64Url(privateSeedBase64),
    );
    final payloadBytes = utf8.encode(jsonEncode(payload));
    final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
    return '$prefix.${_encodeBase64Url(payloadBytes)}.'
        '${_encodeBase64Url(signature.bytes)}';
  }

  static String _encodeBase64Url(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static List<int> _decodeBase64Url(String value) {
    final clean = value.trim();
    final padded = clean.padRight(
      clean.length + (4 - clean.length % 4) % 4,
      '=',
    );
    return base64Url.decode(padded);
  }
}
