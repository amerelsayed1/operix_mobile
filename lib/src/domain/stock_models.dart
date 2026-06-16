// Stock movement domain models — the offline mirror of the cloud stock_movements
// table. Every on-hand quantity change is an immutable, reason-tagged record.
// Kept free of Flutter / database imports.

/// Why a stock movement happened.
enum StockMovementType {
  posSale,
  adjustment,
  correction,
  purchase,
  salesReturn,
  supplierReturn,
  openingStock,
}

extension StockMovementTypeX on StockMovementType {
  String get wire {
    switch (this) {
      case StockMovementType.posSale:
        return 'pos_sale';
      case StockMovementType.adjustment:
        return 'adjustment';
      case StockMovementType.correction:
        return 'correction';
      case StockMovementType.purchase:
        return 'purchase';
      case StockMovementType.salesReturn:
        return 'sales_return';
      case StockMovementType.supplierReturn:
        return 'supplier_return';
      case StockMovementType.openingStock:
        return 'opening_stock';
    }
  }

  String get label {
    switch (this) {
      case StockMovementType.posSale:
        return 'POS sale';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.correction:
        return 'Correction';
      case StockMovementType.purchase:
        return 'Purchase';
      case StockMovementType.salesReturn:
        return 'Sales return';
      case StockMovementType.supplierReturn:
        return 'Supplier return';
      case StockMovementType.openingStock:
        return 'Opening stock';
    }
  }

  static StockMovementType fromWire(String value) =>
      StockMovementType.values.firstWhere(
        (t) => t.wire == value,
        orElse: () => StockMovementType.adjustment,
      );
}

/// Preset reasons offered when making a manual adjustment.
const List<String> kAdjustmentReasons = [
  'Damage',
  'Loss',
  'Theft',
  'Recount',
  'Found',
  'Other',
];

/// A single recorded change to a product's on-hand quantity.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.sku,
    required this.type,
    required this.quantity,
    required this.createdAt,
    this.productId,
    this.reason,
    this.note,
    this.referenceType,
    this.referenceId,
  });

  final int id;
  final int? productId;
  final String productName;
  final String sku;
  final StockMovementType type;
  final int quantity; // signed
  final String? reason;
  final String? note;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;

  bool get isIncrease => quantity > 0;
}
