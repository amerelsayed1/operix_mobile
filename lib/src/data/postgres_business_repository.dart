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
    await _ensureLogoColumn(conn);
    final result = await conn.execute('''
      SELECT business_name, branch_name, logo_path
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
    await _ensureLogoColumn(conn);
    await conn.execute(
      Sql.named('''
        INSERT INTO company_profile (
          id, business_name, branch_name, currency_code, locale, logo_path
        )
        VALUES (1, @business_name, @branch_name, 'EGP', 'en', @logo_path)
        ON CONFLICT (id) DO UPDATE SET
          business_name = EXCLUDED.business_name,
          branch_name = EXCLUDED.branch_name,
          logo_path = EXCLUDED.logo_path
      '''),
      parameters: {
        'business_name': profile.businessName.trim(),
        'branch_name': profile.branchName.trim(),
        'logo_path': _optionalString(profile.logoPath),
      },
    );
    return profile;
  }

  Future<void> _ensureLogoColumn(Connection conn) async {
    await conn.execute(
      'ALTER TABLE company_profile ADD COLUMN IF NOT EXISTS logo_path TEXT',
    );
  }

  String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
