import 'package:postgres/postgres.dart';

import '../domain/customer_models.dart';
import '../domain/value_objects/money.dart';
import 'customer_repository.dart';
import 'operix_database.dart';

class PostgresCustomerRepository implements CustomerRepository {
  PostgresCustomerRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<Customer>> list({
    String search = '',
    bool includeInactive = true,
  }) async {
    final conn = await database.connection();
    final query = search.trim();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, client_code, name, phone, receivable_balance, status,
               created_at
        FROM clients
        WHERE (@include_inactive OR status = 'active')
          AND (
            @q = ''
            OR name ILIKE '%' || @q || '%'
            OR client_code ILIKE '%' || @q || '%'
            OR COALESCE(phone, '') ILIKE '%' || @q || '%'
          )
        ORDER BY name ASC
      '''),
      parameters: {'include_inactive': includeInactive, 'q': query},
    );
    return result.map((row) => _customer(row.toColumnMap())).toList();
  }

  @override
  Future<String> suggestCode() async {
    final conn = await database.connection();
    final result = await conn.execute(
      'SELECT COALESCE(MAX(id), 0) + 1 AS next FROM clients',
    );
    final next = _asInt(result.first.toColumnMap()['next']);
    return 'CUST-${next.toString().padLeft(4, '0')}';
  }

  @override
  Future<Customer> create(CustomerDraft draft) async {
    final conn = await database.connection();
    await _ensureCodeFree(conn, draft.code, null);
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO clients (client_code, name, phone, status)
        VALUES (@code, @name, @phone, @status)
        RETURNING id, client_code, name, phone, receivable_balance, status,
                  created_at
      '''),
      parameters: _params(draft),
    );
    return _customer(result.first.toColumnMap());
  }

  @override
  Future<Customer> update(int id, CustomerDraft draft) async {
    final conn = await database.connection();
    await _ensureCodeFree(conn, draft.code, id);
    // receivable_balance is intentionally left untouched — it is owned by the
    // sales/payment flows, not this form.
    final result = await conn.execute(
      Sql.named('''
        UPDATE clients SET
          client_code = @code,
          name = @name,
          phone = @phone,
          status = @status
        WHERE id = @id
        RETURNING id, client_code, name, phone, receivable_balance, status,
                  created_at
      '''),
      parameters: {..._params(draft), 'id': id},
    );
    if (result.isEmpty) {
      throw const CustomerException('Customer not found.');
    }
    return _customer(result.first.toColumnMap());
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    await conn.execute(
      Sql.named('DELETE FROM clients WHERE id = @id'),
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
        SELECT 1 FROM clients
        WHERE LOWER(client_code) = LOWER(@code)
          AND (@exclude_id::bigint IS NULL OR id <> @exclude_id)
        LIMIT 1
      '''),
      parameters: {'code': code.trim(), 'exclude_id': excludeId},
    );
    if (result.isNotEmpty) {
      throw DuplicateCustomerCodeException(code.trim());
    }
  }

  Map<String, Object?> _params(CustomerDraft d) => {
    'code': d.code.trim(),
    'name': d.name.trim(),
    'phone': (d.phone == null || d.phone!.trim().isEmpty)
        ? null
        : d.phone!.trim(),
    'status': d.status.wireValue,
  };

  Customer _customer(Map<String, dynamic> map) {
    return Customer(
      id: _asInt(map['id']),
      code: _asString(map['client_code']),
      name: _asString(map['name']),
      phone: map['phone'] as String?,
      balance: Money.parse(map['receivable_balance']),
      status: CustomerStatusX.fromWire(map['status'] as String?),
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
