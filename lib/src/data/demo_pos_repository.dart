import '../domain/pos_models.dart';
import 'pos_repository.dart';

/// In-memory POS backend used when PostgreSQL is not configured. Starts with no
/// products or orders; everything is entered through the app. Data resets on
/// restart.
class DemoPosRepository implements PosRepository {
  DemoPosRepository({List<PosProduct> products = const []}) {
    _products.addAll(products);
  }

  final List<PosProduct> _products = [];
  final List<PosReceipt> _orders = [];
  PosShift? _openShift;
  int _receiptSeq = 10500;
  int _shiftSeq = 1001;
  int _orderSeq = 1;

  @override
  bool get isPersistent => false;

  @override
  Future<List<PosProduct>> loadProducts() async => List.unmodifiable(_products);

  @override
  Future<PosShift?> activeShift(int cashierId) async {
    final shift = _openShift;
    if (shift != null && shift.isOpen && shift.cashierId == cashierId) {
      return shift;
    }
    return null;
  }

  @override
  Future<PosShift> openShift({
    required AppUser cashier,
    required double openingFloat,
  }) async {
    final shift = PosShift(
      id: _shiftSeq,
      shiftNumber: 'SH-${_shiftSeq.toString().padLeft(4, '0')}',
      cashierId: cashier.id,
      cashierName: cashier.fullName,
      openingFloat: openingFloat,
      status: 'open',
      openedAt: DateTime.now(),
    );
    _shiftSeq++;
    _openShift = shift;
    return shift;
  }

  @override
  Future<PosShift> closeShift({
    required PosShift shift,
    required double countedCash,
    String? notes,
  }) async {
    final cashSales = _orders.fold<double>(
      0,
      (sum, order) =>
          sum +
          order.payments
              .where((p) => p.method == PaymentMethod.cash)
              .fold<double>(0, (s, p) => s + p.amount),
    );
    final expected = shift.openingFloat + cashSales;
    final closed = PosShift(
      id: shift.id,
      shiftNumber: shift.shiftNumber,
      cashierId: shift.cashierId,
      cashierName: shift.cashierName,
      openingFloat: shift.openingFloat,
      status: 'closed',
      openedAt: shift.openedAt,
      expectedCash: expected,
      countedCash: countedCash,
      cashDifference: countedCash - expected,
      closedAt: DateTime.now(),
      notes: notes,
    );
    _openShift = null;
    return closed;
  }

  @override
  Future<PosReceipt> checkout(CheckoutRequest request) async {
    for (final line in request.lines) {
      final index = _products.indexWhere((p) => p.id == line.product.id);
      if (index >= 0 && _products[index].quantityOnHand < line.quantity) {
        throw InsufficientStockException(line.product.name);
      }
    }
    for (final line in request.lines) {
      final index = _products.indexWhere((p) => p.id == line.product.id);
      if (index >= 0) {
        _products[index] = _products[index].copyWith(
          quantityOnHand: _products[index].quantityOnHand - line.quantity,
        );
      }
    }

    final receipt = PosReceipt(
      id: _orderSeq++,
      receiptNumber: 'POS-${(_receiptSeq++).toString().padLeft(6, '0')}',
      cashierName: request.cashier.fullName,
      createdAt: DateTime.now(),
      lines: request.lines
          .map(
            (line) => ReceiptLine(
              name: line.product.name,
              sku: line.product.sku,
              quantity: line.quantity,
              unitPrice: line.product.unitPrice,
            ),
          )
          .toList(),
      payments: request.payments,
      subtotal: request.subtotal,
      discount: request.discount,
      tax: request.tax,
      total: request.total,
      paidAmount: request.paidAmount,
      changeAmount: request.changeAmount,
      customerName: request.customerName,
    );
    _orders.insert(0, receipt);
    return receipt;
  }

  @override
  Future<List<PosOrderSummary>> recentOrders({
    int? shiftId,
    int limit = 50,
  }) async {
    return _orders
        .take(limit)
        .map(
          (order) => PosOrderSummary(
            id: order.id,
            receiptNumber: order.receiptNumber,
            createdAt: order.createdAt,
            total: order.total,
            itemCount: order.itemCount,
            paymentSummary: order.payments
                .map((p) => p.method.wireValue)
                .toSet()
                .join('+'),
            status: 'completed',
          ),
        )
        .toList();
  }

  @override
  Future<PosReceipt> orderReceipt(int orderId) async {
    return _orders.firstWhere(
      (order) => order.id == orderId,
      orElse: () => throw const PosException('Order not found.'),
    );
  }
}
