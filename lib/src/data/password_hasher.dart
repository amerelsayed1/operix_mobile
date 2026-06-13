import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 password hashing.
///
/// Encoded format (Django-compatible): `pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>`.
/// Hashing lives entirely in the Dart client so there is a single source of
/// truth; the database only ever stores the encoded string.
class PasswordHasher {
  const PasswordHasher._();

  static const int _iterations = 120000;
  static const int _keyLength = 32; // bytes
  static const String _algorithm = 'pbkdf2_sha256';

  static final Random _random = Random.secure();

  /// Produces an encoded hash for [password] using a fresh random salt.
  static String hash(String password) {
    final salt = _randomBytes(16);
    final derived = _pbkdf2(
      utf8.encode(password),
      salt,
      _iterations,
      _keyLength,
    );
    return '$_algorithm\$$_iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  /// Verifies [password] against a previously [hash]ed [encoded] value.
  static bool verify(String password, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _algorithm) {
      return false;
    }
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) {
      return false;
    }
    Uint8List salt;
    Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    final derived = _pbkdf2(
      utf8.encode(password),
      salt,
      iterations,
      expected.length,
    );
    return _constantTimeEquals(derived, expected);
  }

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    const blockSize = 32; // sha256 output size
    final blockCount = (keyLength / blockSize).ceil();
    final output = BytesBuilder();

    for (var block = 1; block <= blockCount; block++) {
      final blockIndex = Uint8List(4)
        ..buffer.asByteData().setUint32(0, block, Endian.big);
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
    }

    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
