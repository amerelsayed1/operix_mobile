import 'package:postgres/postgres.dart';

import '../domain/supplier_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'supplier_repository.dart';

class PostgresSupplierRepository implements SupplierRepository {
  PostgresSupplierRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<Supplier>> list({
    String search = '',
    bool includeInactive = true,
  }) async {
    final conn = await database.connection();
    final query = search.trim();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, supplier_code, company_name, phone, payable_balance, status,
               created_at
        FROM suppliers
        WHERE (@include_inactive OR status = 'active')
          AND (
            @q = ''
            OR company_name ILIKE '%' || @q || '%'
            OR supplier_code ILIKE '%' || @q || '%'
            OR COALESCE(phone, '') ILIKE '%' || @q || '%'
          )
        ORDER BY company_name ASC
      '''),
      parameters: {'include_inactive': includeInactive, 'q': query},
    );
    return result.map((row) => _supplier(row.toColumnMap())).toList();
  }

  @override
  Future<String> suggestCode() async {
    final conn = await database.connection();
    final result = await conn.execute(
      'SELECT COALESCE(MAX(id), 0) + 1 AS next FROM suppliers',
    );
    final next = _asInt(result.first.toColumnMap()['next']);
    return 'SUP-${next.toString().padLeft(4, '0')}';
  }

  @override
  Future<Supplier> create(SupplierDraft draft) async {
    final conn = await database.connection();
    await _ensureCodeFree(conn, draft.code, null);
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO suppliers (supplier_code, company_name, phone, status)
        VALUES (@code, @name, @phone, @status)
        RETURNING id, supplier_code, company_name, phone, payable_balance,
                  status, created_at
      '''),
      parameters: _params(draft),
    );
    return _supplier(result.first.toColumnMap());
  }

  @override
  Future<Supplier> update(int id, SupplierDraft draft) async {
    final conn = await database.connection();
    await _ensureCodeFree(conn, draft.code, id);
    // payable_balance is intentionally left untouched — it is owned by the
    // purchase/payment flows, not this form.
    final result = await conn.execute(
      Sql.named('''
        UPDATE suppliers SET
          supplier_code = @code,
          company_name = @name,
          phone = @phone,
          status = @status
        WHERE id = @id
        RETURNING id, supplier_code, company_name, phone, payable_balance,
                  status, created_at
      '''),
      parameters: {..._params(draft), 'id': id},
    );
    if (result.isEmpty) {
      throw const SupplierException('Supplier not found.');
    }
    return _supplier(result.first.toColumnMap());
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    await conn.execute(
      Sql.named('DELETE FROM suppliers WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<void> _ensureCodeFree(
    Connection conn,
    String code,
    int? excludeId,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM suppliers
        WHERE LOWER(supplier_code) = LOWER(@code)
          AND (@exclude_id::bigint IS NULL OR id <> @exclude_id)
        LIMIT 1
      '''),
      parameters: {'code': code.trim(), 'exclude_id': excludeId},
    );
    if (result.isNotEmpty) {
      throw DuplicateSupplierCodeException(code.trim());
    }
  }

  Map<String, Object?> _params(SupplierDraft d) => {
    'code': d.code.trim(),
    'name': d.companyName.trim(),
    'phone': (d.phone == null || d.phone!.trim().isEmpty)
        ? null
        : d.phone!.trim(),
    'status': d.status.wireValue,
  };

  Supplier _supplier(Map<String, dynamic> map) {
    return Supplier(
      id: _asInt(map['id']),
      code: _asString(map['supplier_code']),
      companyName: _asString(map['company_name']),
      phone: map['phone'] as String?,
      balance: Money.parse(map['payable_balance']),
      status: SupplierStatusX.fromWire(map['status'] as String?),
      createdAt: _asDateOrNull(map['created_at']),
    );
  }

  String _asString(Object? v) => v?.toString() ?? '';

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  DateTime? _asDateOrNull(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
