import 'package:postgres/postgres.dart';

import '../domain/inventory_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'product_repository.dart';

class PostgresProductRepository implements ProductRepository {
  PostgresProductRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<Product>> list({
    String search = '',
    bool includeInactive = true,
    bool inStockOnly = false,
  }) async {
    final conn = await database.connection();
    final query = search.trim();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, sku, name, barcode, category, unit, cost_price, unit_price,
               reorder_level, quantity_on_hand, is_active
        FROM products
        WHERE (@include_inactive OR is_active = TRUE)
          AND (NOT @in_stock_only OR quantity_on_hand > 0)
          AND (
            @q = ''
            OR name ILIKE '%' || @q || '%'
            OR sku ILIKE '%' || @q || '%'
            OR COALESCE(barcode, '') ILIKE '%' || @q || '%'
            OR category ILIKE '%' || @q || '%'
          )
        ORDER BY name ASC
      '''),
      parameters: {
        'include_inactive': includeInactive,
        'in_stock_only': inStockOnly,
        'q': query,
      },
    );
    return result.map((row) => _product(row.toColumnMap())).toList();
  }

  @override
  Future<List<String>> categories() async {
    final conn = await database.connection();
    final result = await conn.execute(
      "SELECT DISTINCT category FROM products WHERE category <> '' ORDER BY category ASC",
    );
    return result
        .map((row) => _asString(row.toColumnMap()['category']))
        .toList();
  }

  @override
  Future<String> suggestSku() async {
    final conn = await database.connection();
    final result = await conn.execute(
      'SELECT COALESCE(MAX(id), 0) + 1 AS next FROM products',
    );
    final next = _asInt(result.first.toColumnMap()['next']);
    return 'SKU-${next.toString().padLeft(4, '0')}';
  }

  @override
  Future<Product> create(ProductDraft draft) async {
    final conn = await database.connection();
    await _ensureSkuFree(conn, draft.sku, null);
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO products (
          sku, name, barcode, category, unit, cost_price, unit_price,
          reorder_level, quantity_on_hand, is_active
        ) VALUES (
          @sku, @name, @barcode, @category, @unit, @cost_price, @selling_price,
          @minimum_stock_alert, @quantity_on_hand, @is_active
        )
        RETURNING id, sku, name, barcode, category, unit, cost_price, unit_price,
                  reorder_level, quantity_on_hand, is_active
      '''),
      parameters: _params(draft),
    );
    return _product(result.first.toColumnMap());
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    final conn = await database.connection();
    await _ensureSkuFree(conn, draft.sku, id);
    final result = await conn.execute(
      Sql.named('''
        UPDATE products SET
          sku = @sku,
          name = @name,
          barcode = @barcode,
          category = @category,
          unit = @unit,
          cost_price = @cost_price,
          unit_price = @selling_price,
          reorder_level = @minimum_stock_alert,
          quantity_on_hand = @quantity_on_hand,
          is_active = @is_active
        WHERE id = @id
        RETURNING id, sku, name, barcode, category, unit, cost_price, unit_price,
                  reorder_level, quantity_on_hand, is_active
      '''),
      parameters: {..._params(draft), 'id': id},
    );
    if (result.isEmpty) {
      throw const ProductException('Product not found.');
    }
    return _product(result.first.toColumnMap());
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    await conn.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<void> _ensureSkuFree(
    Connection conn,
    String sku,
    int? excludeId,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM products
        WHERE LOWER(sku) = LOWER(@sku) AND (@exclude_id::bigint IS NULL OR id <> @exclude_id)
        LIMIT 1
      '''),
      parameters: {'sku': sku.trim(), 'exclude_id': excludeId},
    );
    if (result.isNotEmpty) {
      throw DuplicateSkuException(sku.trim());
    }
  }

  Map<String, Object?> _params(ProductDraft d) => {
    'sku': d.sku.trim(),
    'name': d.name.trim(),
    'barcode': (d.barcode == null || d.barcode!.trim().isEmpty)
        ? null
        : d.barcode!.trim(),
    'category': d.category.trim().isEmpty ? 'General' : d.category.trim(),
    'unit': d.unit.trim().isEmpty ? 'Piece' : d.unit.trim(),
    'cost_price': d.costPrice.toStorageString(),
    'selling_price': d.sellingPrice.toStorageString(),
    'minimum_stock_alert': d.minimumStockAlert,
    'quantity_on_hand': d.quantityOnHand,
    'is_active': d.isActive,
  };

  Product _product(Map<String, dynamic> map) {
    return Product(
      id: _asInt(map['id']),
      sku: _asString(map['sku']),
      name: _asString(map['name']),
      barcode: map['barcode'] as String?,
      category: _asString(map['category']),
      unit: _asString(map['unit']),
      costPrice: _asMoney(map['cost_price']),
      sellingPrice: _asMoney(map['unit_price']),
      minimumStockAlert: _asInt(map['reorder_level']),
      quantityOnHand: _asInt(map['quantity_on_hand']),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  String _asString(Object? v) => v?.toString() ?? '';

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Money _asMoney(Object? v) => Money.parse(v);
}
