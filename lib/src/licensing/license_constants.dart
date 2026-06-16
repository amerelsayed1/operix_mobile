const String kOperixLicenseProduct = 'operix-desktop';

/// Development public key shipped with the local license-creation tool. The
/// matching private seed is widely known, so any release built without
/// overriding [kOperixLicensePublicKey] could be fed forged licenses. Release
/// builds reject this key at runtime (see [isUsingDevLicenseKey]).
const String kOperixDevLicensePublicKey =
    'qeN_A-rifW2qLXTCS7Ua0r7cmwhMgl_niXlJ7tpIhEg';

// Public key used to verify license signatures. Override at build time with
// --dart-define=OPERIX_LICENSE_PUBLIC_KEY=<production key> for release builds.
const String kOperixLicensePublicKey = String.fromEnvironment(
  'OPERIX_LICENSE_PUBLIC_KEY',
  defaultValue: kOperixDevLicensePublicKey,
);

/// Whether the build is still verifying licenses with the insecure development
/// key. Used to fail closed in production rather than trust forgeable licenses.
bool get isUsingDevLicenseKey =>
    kOperixLicensePublicKey == kOperixDevLicensePublicKey;
