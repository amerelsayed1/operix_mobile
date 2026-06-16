import '../domain/catalog_models.dart';

/// Manages the product-category catalogue (Settings → Item categories).
abstract interface class CategoryRepository {
  /// All categories, optionally filtered by a name search (EN or AR).
  Future<List<ProductCategory>> list({String search = ''});

  Future<ProductCategory> create(CategoryDraft draft);

  Future<ProductCategory> update(int id, CategoryDraft draft);

  Future<void> delete(int id);
}
