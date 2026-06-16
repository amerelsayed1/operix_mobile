import '../domain/stock_models.dart';
import '../domain/value_objects/money.dart';
import 'stock_repository.dart';

/// In-memory stock log used when PostgreSQL is not configured. The demo product
/// store is separate, so adjustments are recorded but not reflected in stock.
class DemoStockRepository implements StockRepository {
  final List<StockMovement> _movements = [];
  int _seq = 1;

  @override
  Future<List<StockMovement>> recentMovements({
    int? productId,
    int limit = 100,
  }) async {
    final rows = _movements
        .where((m) => productId == null || m.productId == productId)
        .take(limit)
        .toList();
    return rows;
  }

  @override
  Future<void> adjust({
    required int productId,
    required int delta,
    required String reason,
    String? note,
    int? userId,
    Money? unitCost,
  }) async {
    _movements.insert(
      0,
      StockMovement(
        id: _seq++,
        productId: productId,
        productName: 'Product #$productId',
        sku: '',
        type: StockMovementType.adjustment,
        quantity: delta,
        reason: reason,
        note: note,
        createdAt: DateTime.now(),
      ),
    );
  }
}
