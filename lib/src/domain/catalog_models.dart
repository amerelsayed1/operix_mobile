// Product catalogue settings — managed Categories and Units (the offline mirror
// of the web tenant app's product_categories + units). Both carry bilingual
// (EN/AR) names; [displayName] picks the right one for the active locale and
// [canonicalName] is the single string stored on a product (back-compat with the
// free-text product.category / product.unit columns). Free of Flutter / DB imports.

String _pick(bool arabic, String nameEn, String nameAr) {
  if (arabic) return nameAr.trim().isNotEmpty ? nameAr : nameEn;
  return nameEn.trim().isNotEmpty ? nameEn : nameAr;
}

/// A managed product category.
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.isActive = true,
    this.productsCount = 0,
  });

  final int id;
  final String nameEn;
  final String nameAr;
  final bool isActive;
  final int productsCount;

  String displayName(bool arabic) => _pick(arabic, nameEn, nameAr);

  /// The value persisted on a product (English preferred, Arabic fallback).
  String get canonicalName => _pick(false, nameEn, nameAr);
}

/// A managed unit of measure.
class Unit {
  const Unit({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.shortCode,
    this.description,
    this.allowDecimal = false,
    this.isDefault = false,
    this.isActive = true,
  });

  final int id;
  final String nameEn;
  final String nameAr;
  final String? shortCode;
  final String? description;
  final bool allowDecimal;
  final bool isDefault;
  final bool isActive;

  String displayName(bool arabic) => _pick(arabic, nameEn, nameAr);

  String get canonicalName => _pick(false, nameEn, nameAr);
}

/// Create/update input for a category.
class CategoryDraft {
  const CategoryDraft({required this.nameEn, required this.nameAr});
  final String nameEn;
  final String nameAr;
}

/// Create/update input for a unit.
class UnitDraft {
  const UnitDraft({
    required this.nameEn,
    required this.nameAr,
    this.shortCode,
    this.description,
    this.allowDecimal = false,
  });
  final String nameEn;
  final String nameAr;
  final String? shortCode;
  final String? description;
  final bool allowDecimal;
}

class CategoryException implements Exception {
  const CategoryException(this.message);
  final String message;
  @override
  String toString() => 'CategoryException: $message';
}

class UnitException implements Exception {
  const UnitException(this.message);
  final String message;
  @override
  String toString() => 'UnitException: $message';
}
