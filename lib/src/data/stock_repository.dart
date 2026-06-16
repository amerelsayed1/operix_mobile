import '../domain/stock_models.dart';
import '../domain/value_objects/money.dart';

class StockException implements Exception {
  const StockException(this.message);
  final String message;
  @override
  String toString() => 'StockException: $message';
}

/// Reads the stock-movement log and applies manual adjustments.
abstract interface class StockRepository {
  /// Recent movements, newest first, optionally scoped to one product.
  Future<List<StockMovement>> recentMovements({
    int? productId,
    int limit = 100,
  });

  /// Applies a signed [delta] to a product's on-hand quantity, records the
  /// movement, and posts the matching GL entry (Inventory vs. Inventory
  /// Adjustment) so the books stay in step with the count.
  ///
  /// For an *increase*, [unitCost] is the cost the units are brought in at; it is
  /// weighted into the product's average cost. When omitted (or zero) the
  /// product's current cost is used. For a *decrease* the current cost is always
  /// used. Throws [StockException] if the result would go negative.
  Future<void> adjust({
    required int productId,
    required int delta,
    required String reason,
    String? note,
    int? userId,
    Money? unitCost,
  });
}
