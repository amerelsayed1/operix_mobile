import 'package:postgres/postgres.dart';

import '../domain/catalog_models.dart';
import 'operix_database.dart';
import 'unit_repository.dart';

class PostgresUnitRepository implements UnitRepository {
  PostgresUnitRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<Unit>> list() async {
    final conn = await database.connection();
    final result = await conn.execute('''
      SELECT id, name_en, name_ar, short_code, description, allow_decimal,
             is_default, is_active
      FROM units
      ORDER BY is_default DESC, name_en ASC, name_ar ASC
    ''');
    return result.map((row) => _fromRow(row.toColumnMap())).toList();
  }

  @override
  Future<Unit> create(UnitDraft draft) async {
    final (en, ar) = _normalize(draft);
    final conn = await database.connection();
    // If this is the very first unit, make it the default so a product always
    // has a unit to fall back to.
    return conn.runTx((session) async {
      final count = await session.execute(
        'SELECT COUNT(*)::int AS n FROM units',
      );
      final isFirst = _asInt(count.first.toColumnMap()['n']) == 0;
      final result = await session.execute(
        Sql.named('''
          INSERT INTO units
            (name_en, name_ar, short_code, description, allow_decimal, is_default)
          VALUES (@en, @ar, @code, @desc, @decimal, @def)
          RETURNING id, name_en, name_ar, short_code, description, allow_decimal,
                    is_default, is_active
        '''),
        parameters: {
          'en': en,
          'ar': ar,
          'code': draft.shortCode?.trim().isEmpty ?? true
              ? null
              : draft.shortCode!.trim(),
          'desc': draft.description?.trim().isEmpty ?? true
              ? null
              : draft.description!.trim(),
          'decimal': draft.allowDecimal,
          'def': isFirst,
        },
      );
      return _fromRow(result.first.toColumnMap());
    });
  }

  @override
  Future<Unit> update(int id, UnitDraft draft) async {
    final (en, ar) = _normalize(draft);
    final conn = await database.connection();
    final result = await conn.execute(
      Sql.named('''
        UPDATE units
        SET name_en = @en, name_ar = @ar, short_code = @code,
            description = @desc, allow_decimal = @decimal, updated_at = NOW()
        WHERE id = @id
        RETURNING id, name_en, name_ar, short_code, description, allow_decimal,
                  is_default, is_active
      '''),
      parameters: {
        'en': en,
        'ar': ar,
        'code': draft.shortCode?.trim().isEmpty ?? true
            ? null
            : draft.shortCode!.trim(),
        'desc': draft.description?.trim().isEmpty ?? true
            ? null
            : draft.description!.trim(),
        'decimal': draft.allowDecimal,
        'id': id,
      },
    );
    if (result.isEmpty) {
      throw const UnitException('Unit not found.');
    }
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    // If the default is removed, promote another unit so one default remains.
    await conn.runTx((session) async {
      final removed = await session.execute(
        Sql.named('DELETE FROM units WHERE id = @id RETURNING is_default'),
        parameters: {'id': id},
      );
      if (removed.isEmpty) return;
      final wasDefault =
          removed.first.toColumnMap()['is_default'] as bool? ?? false;
      if (wasDefault) {
        await session.execute('''
          UPDATE units SET is_default = TRUE
          WHERE id = (SELECT id FROM units ORDER BY name_en ASC LIMIT 1)
        ''');
      }
    });
  }

  @override
  Future<void> setDefault(int id) async {
    final conn = await database.connection();
    // Clear the current default before setting the new one so the single-default
    // unique index is never transiently violated mid-statement.
    await conn.runTx((session) async {
      await session.execute(
        'UPDATE units SET is_default = FALSE WHERE is_default = TRUE',
      );
      final updated = await session.execute(
        Sql.named('UPDATE units SET is_default = TRUE WHERE id = @id'),
        parameters: {'id': id},
      );
      if (updated.affectedRows == 0) {
        throw const UnitException('Unit not found.');
      }
    });
  }

  (String, String) _normalize(UnitDraft draft) {
    final en = draft.nameEn.trim();
    final ar = draft.nameAr.trim();
    if (en.isEmpty && ar.isEmpty) {
      throw const UnitException('Enter a unit name.');
    }
    return (en.isNotEmpty ? en : ar, ar.isNotEmpty ? ar : en);
  }

  Unit _fromRow(Map<String, dynamic> m) => Unit(
    id: _asInt(m['id']),
    nameEn: m['name_en']?.toString() ?? '',
    nameAr: m['name_ar']?.toString() ?? '',
    shortCode: m['short_code'] as String?,
    description: m['description'] as String?,
    allowDecimal: m['allow_decimal'] as bool? ?? false,
    isDefault: m['is_default'] as bool? ?? false,
    isActive: m['is_active'] as bool? ?? true,
  );

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
