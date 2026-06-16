import 'package:postgres/postgres.dart';

import '../domain/catalog_models.dart';
import 'category_repository.dart';
import 'operix_database.dart';

class PostgresCategoryRepository implements CategoryRepository {
  PostgresCategoryRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<ProductCategory>> list({String search = ''}) async {
    final conn = await database.connection();
    final q = search.trim();
    final result = await conn.execute(
      Sql.named('''
        SELECT c.id, c.name_en, c.name_ar, c.is_active,
               (SELECT COUNT(*) FROM products p
                  WHERE p.category = c.name_en OR p.category = c.name_ar)::int
                 AS products_count
        FROM product_categories c
        WHERE (@q = '' OR c.name_en ILIKE '%' || @q || '%'
                      OR c.name_ar ILIKE '%' || @q || '%')
        ORDER BY c.name_en ASC, c.name_ar ASC
      '''),
      parameters: {'q': q},
    );
    return result.map((row) => _fromRow(row.toColumnMap())).toList();
  }

  @override
  Future<ProductCategory> create(CategoryDraft draft) async {
    final (en, ar) = _normalize(draft);
    final conn = await database.connection();
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO product_categories (name_en, name_ar)
        VALUES (@en, @ar)
        RETURNING id, name_en, name_ar, is_active
      '''),
      parameters: {'en': en, 'ar': ar},
    );
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<ProductCategory> update(int id, CategoryDraft draft) async {
    final (en, ar) = _normalize(draft);
    final conn = await database.connection();
    final result = await conn.execute(
      Sql.named('''
        UPDATE product_categories
        SET name_en = @en, name_ar = @ar, updated_at = NOW()
        WHERE id = @id
        RETURNING id, name_en, name_ar, is_active
      '''),
      parameters: {'en': en, 'ar': ar, 'id': id},
    );
    if (result.isEmpty) {
      throw const CategoryException('Category not found.');
    }
    return _fromRow(result.first.toColumnMap());
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    await conn.execute(
      Sql.named('DELETE FROM product_categories WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  /// At least one name is required; the empty side mirrors the filled one — the
  /// same rule the web form applies.
  (String, String) _normalize(CategoryDraft draft) {
    final en = draft.nameEn.trim();
    final ar = draft.nameAr.trim();
    if (en.isEmpty && ar.isEmpty) {
      throw const CategoryException('Enter a category name.');
    }
    return (en.isNotEmpty ? en : ar, ar.isNotEmpty ? ar : en);
  }

  ProductCategory _fromRow(Map<String, dynamic> m) => ProductCategory(
    id: _asInt(m['id']),
    nameEn: m['name_en']?.toString() ?? '',
    nameAr: m['name_ar']?.toString() ?? '',
    isActive: m['is_active'] as bool? ?? true,
    productsCount: _asInt(m['products_count']),
  );

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
