const String kOperixLicenseProduct = 'operix-desktop';

// Development public key used by the local license creation tool. Replace this
// with a production public key before distributing release builds.
const String kOperixLicensePublicKey = String.fromEnvironment(
  'OPERIX_LICENSE_PUBLIC_KEY',
  defaultValue: 'qeN_A-rifW2qLXTCS7Ua0r7cmwhMgl_niXlJ7tpIhEg',
);
