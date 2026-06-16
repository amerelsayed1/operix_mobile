import 'package:postgres/postgres.dart';

import '../domain/business_profile.dart';
import 'business_repository.dart';
import 'operix_database.dart';

class PostgresBusinessRepository implements BusinessRepository {
  PostgresBusinessRepository(this.database);

  final OperixDatabase database;

  @override
  Future<BusinessProfile?> loadProfile() async {
    final conn = await database.connection();
    await _ensureColumns(conn);
    final result = await conn.execute('''
      SELECT business_name, branch_name, logo_path, email, phone,
             phone_country_code, commercial_registration, city, region,
             country, postal_code, address
      FROM company_profile
      WHERE id = 1
      LIMIT 1
    ''');

    if (result.isEmpty) {
      return null;
    }

    final row = result.first.toColumnMap();
    return BusinessProfile(
      businessName: row['business_name'] as String? ?? '',
      branchName: row['branch_name'] as String? ?? '',
      logoPath: _optionalString(row['logo_path']),
      email: _optionalString(row['email']),
      phone: _optionalString(row['phone']),
      phoneCountryCode: _optionalString(row['phone_country_code']) ?? '+20',
      commercialRegistration: _optionalString(row['commercial_registration']),
      city: _optionalString(row['city']),
      region: _optionalString(row['region']),
      country: _optionalString(row['country']),
      postalCode: _optionalString(row['postal_code']),
      address: _optionalString(row['address']),
    );
  }

  @override
  Future<bool> hasProfile() async {
    final conn = await database.connection();
    final result = await conn.execute(
      'SELECT EXISTS(SELECT 1 FROM company_profile WHERE id = 1) AS present',
    );
    return result.first.toColumnMap()['present'] as bool? ?? false;
  }

  @override
  Future<BusinessProfile> saveProfile(BusinessProfile profile) async {
    final conn = await database.connection();
    await _ensureColumns(conn);
    await conn.execute(
      Sql.named('''
        INSERT INTO company_profile (
          id, business_name, branch_name, currency_code, locale, logo_path,
          email, phone, phone_country_code, commercial_registration, city,
          region, country, postal_code, address
        )
        VALUES (
          1, @business_name, @branch_name, 'EGP', 'en', @logo_path,
          @email, @phone, @phone_country_code, @commercial_registration, @city,
          @region, @country, @postal_code, @address
        )
        ON CONFLICT (id) DO UPDATE SET
          business_name = EXCLUDED.business_name,
          branch_name = EXCLUDED.branch_name,
          logo_path = EXCLUDED.logo_path,
          email = EXCLUDED.email,
          phone = EXCLUDED.phone,
          phone_country_code = EXCLUDED.phone_country_code,
          commercial_registration = EXCLUDED.commercial_registration,
          city = EXCLUDED.city,
          region = EXCLUDED.region,
          country = EXCLUDED.country,
          postal_code = EXCLUDED.postal_code,
          address = EXCLUDED.address
      '''),
      parameters: {
        'business_name': profile.businessName.trim(),
        'branch_name': profile.branchName.trim(),
        'logo_path': _optionalString(profile.logoPath),
        'email': _optionalString(profile.email),
        'phone': _optionalString(profile.phone),
        'phone_country_code': profile.phoneCountryCode.trim(),
        'commercial_registration': _optionalString(
          profile.commercialRegistration,
        ),
        'city': _optionalString(profile.city),
        'region': _optionalString(profile.region),
        'country': _optionalString(profile.country),
        'postal_code': _optionalString(profile.postalCode),
        'address': _optionalString(profile.address),
      },
    );
    return profile;
  }

  /// Adds the company-information columns if an older schema is in place.
  /// Idempotent and safe to run on every load/save.
  Future<void> _ensureColumns(Connection conn) async {
    const columns = {
      'logo_path': 'TEXT',
      'email': 'VARCHAR(160)',
      'phone': 'VARCHAR(60)',
      "phone_country_code": "VARCHAR(8) NOT NULL DEFAULT '+20'",
      'commercial_registration': 'VARCHAR(80)',
      'city': 'VARCHAR(120)',
      'region': 'VARCHAR(120)',
      'country': 'VARCHAR(80)',
      'postal_code': 'VARCHAR(40)',
      'address': 'TEXT',
    };
    for (final entry in columns.entries) {
      await conn.execute(
        'ALTER TABLE company_profile '
        'ADD COLUMN IF NOT EXISTS ${entry.key} ${entry.value}',
      );
    }
  }

  String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
