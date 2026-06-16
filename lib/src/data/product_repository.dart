import '../domain/inventory_models.dart';

class ProductException implements Exception {
  const ProductException(this.message);
  final String message;
  @override
  String toString() => 'ProductException: $message';
}

/// Raised when a SKU collides with an existing product.
class DuplicateSkuException extends ProductException {
  const DuplicateSkuException(String sku)
    : super('A product with SKU "$sku" already exists.');
}

abstract interface class ProductRepository {
  /// Lists products for catalogue/picker use. Set [inStockOnly] to hide items
  /// with no quantity on hand (used by the sales-invoice picker — you can't sell
  /// what isn't there; the purchase picker leaves it false so you can restock).
  Future<List<Product>> list({
    String search = '',
    bool includeInactive = true,
    bool inStockOnly = false,
  });

  /// Distinct category names already in use (for the category picker).
  Future<List<String>> categories();

  /// A suggested next SKU, e.g. `SKU-0007`.
  Future<String> suggestSku();

  Future<Product> create(ProductDraft draft);

  Future<Product> update(int id, ProductDraft draft);

  Future<void> delete(int id);
}
