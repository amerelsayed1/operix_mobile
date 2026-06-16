import '../domain/pos_models.dart';
import '../domain/value_objects/money.dart';

class PosException implements Exception {
  const PosException(this.message);
  final String message;
  @override
  String toString() => 'PosException: $message';
}

/// Raised by [PosRepository.checkout] when a line would oversell stock.
class InsufficientStockException extends PosException {
  const InsufficientStockException(this.productName)
    : super('Not enough stock for "$productName".');
  final String productName;
}

abstract interface class PosRepository {
  /// Whether this repository is backed by a real database (vs. in-memory demo).
  bool get isPersistent;

  Future<List<PosProduct>> loadProducts();

  /// The currently open shift for [cashierId], or null if none is open.
  Future<PosShift?> activeShift(int cashierId);

  Future<PosShift> openShift({
    required AppUser cashier,
    required Money openingFloat,
  });

  Future<PosShift> closeShift({
    required PosShift shift,
    required Money countedCash,
    String? notes,
  });

  /// Persists a sale, decrements inventory, and returns the printable receipt.
  Future<PosReceipt> checkout(CheckoutRequest request);

  /// Recent orders, optionally scoped to a shift.
  Future<List<PosOrderSummary>> recentOrders({int? shiftId, int limit = 50});

  /// Full receipt for a previously persisted order.
  Future<PosReceipt> orderReceipt(int orderId);
}
