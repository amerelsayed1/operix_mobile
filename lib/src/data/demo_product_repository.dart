import '../domain/inventory_models.dart';
import 'product_repository.dart';

/// In-memory product store used when PostgreSQL is not configured. Starts empty.
class DemoProductRepository implements ProductRepository {
  final List<Product> _products = [];
  int _seq = 1;

  @override
  Future<List<Product>> list({
    String search = '',
    bool includeInactive = true,
    bool inStockOnly = false,
  }) async {
    final q = search.trim().toLowerCase();
    final filtered =
        _products.where((p) {
          if (!includeInactive && !p.isActive) return false;
          if (inStockOnly && p.quantityOnHand <= 0) return false;
          if (q.isEmpty) return true;
          return p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              (p.barcode ?? '').toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q);
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return filtered;
  }

  @override
  Future<List<String>> categories() async {
    final set = <String>{
      for (final p in _products)
        if (p.category.isNotEmpty) p.category,
    };
    return set.toList()..sort();
  }

  @override
  Future<String> suggestSku() async =>
      'SKU-${(_products.length + 1).toString().padLeft(4, '0')}';

  @override
  Future<Product> create(ProductDraft draft) async {
    if (_products.any(
      (p) => p.sku.toLowerCase() == draft.sku.trim().toLowerCase(),
    )) {
      throw DuplicateSkuException(draft.sku.trim());
    }
    final product = _fromDraft(_seq++, draft);
    _products.add(product);
    return product;
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index < 0) throw const ProductException('Product not found.');
    if (_products.any(
      (p) =>
          p.id != id && p.sku.toLowerCase() == draft.sku.trim().toLowerCase(),
    )) {
      throw DuplicateSkuException(draft.sku.trim());
    }
    final product = _fromDraft(id, draft);
    _products[index] = product;
    return product;
  }

  @override
  Future<void> delete(int id) async {
    _products.removeWhere((p) => p.id == id);
  }

  Product _fromDraft(int id, ProductDraft d) {
    return Product(
      id: id,
      sku: d.sku.trim(),
      name: d.name.trim(),
      barcode: (d.barcode == null || d.barcode!.trim().isEmpty)
          ? null
          : d.barcode!.trim(),
      category: d.category.trim().isEmpty ? 'General' : d.category.trim(),
      unit: d.unit.trim().isEmpty ? 'Piece' : d.unit.trim(),
      costPrice: d.costPrice,
      sellingPrice: d.sellingPrice,
      minimumStockAlert: d.minimumStockAlert,
      quantityOnHand: d.quantityOnHand,
      isActive: d.isActive,
    );
  }
}
