// Inventory domain models for product management (the create/edit form and the
// products list). Mirrors the Operix web product fields.

/// Common units offered in the product form (free text is also allowed).
const List<String> kProductUnits = [
  'Piece',
  'Box',
  'Pack',
  'Dozen',
  'Kg',
  'Gram',
  'Liter',
  'Meter',
];

/// A fully persisted product.
class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.minimumStockAlert,
    required this.quantityOnHand,
    required this.isActive,
    this.barcode,
  });

  final int id;
  final String sku;
  final String name;
  final String? barcode;
  final String category;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final int minimumStockAlert;
  final int quantityOnHand;
  final bool isActive;

  bool get isLowStock => quantityOnHand <= minimumStockAlert;
  double get margin => sellingPrice - costPrice;
}

/// Input for creating or updating a product.
class ProductDraft {
  const ProductDraft({
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.minimumStockAlert,
    required this.quantityOnHand,
    required this.isActive,
    this.barcode,
  });

  final String sku;
  final String name;
  final String? barcode;
  final String category;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final int minimumStockAlert;
  final int quantityOnHand;
  final bool isActive;
}
