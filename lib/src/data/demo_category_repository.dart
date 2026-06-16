import '../domain/catalog_models.dart';
import 'category_repository.dart';

/// In-memory category catalogue used when PostgreSQL is not configured.
class DemoCategoryRepository implements CategoryRepository {
  final List<ProductCategory> _items = [];
  int _seq = 1;

  @override
  Future<List<ProductCategory>> list({String search = ''}) async {
    final q = search.trim().toLowerCase();
    final rows = _items.where((c) {
      if (q.isEmpty) return true;
      return c.nameEn.toLowerCase().contains(q) ||
          c.nameAr.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.canonicalName.compareTo(b.canonicalName));
    return rows;
  }

  @override
  Future<ProductCategory> create(CategoryDraft draft) async {
    final (en, ar) = _normalize(draft);
    final category = ProductCategory(id: _seq++, nameEn: en, nameAr: ar);
    _items.add(category);
    return category;
  }

  @override
  Future<ProductCategory> update(int id, CategoryDraft draft) async {
    final (en, ar) = _normalize(draft);
    final index = _items.indexWhere((c) => c.id == id);
    if (index < 0) throw const CategoryException('Category not found.');
    final updated = ProductCategory(id: id, nameEn: en, nameAr: ar);
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((c) => c.id == id);
  }

  (String, String) _normalize(CategoryDraft draft) {
    final en = draft.nameEn.trim();
    final ar = draft.nameAr.trim();
    if (en.isEmpty && ar.isEmpty) {
      throw const CategoryException('Enter a category name.');
    }
    return (en.isNotEmpty ? en : ar, ar.isNotEmpty ? ar : en);
  }
}
