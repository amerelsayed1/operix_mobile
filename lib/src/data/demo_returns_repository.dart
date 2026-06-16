import '../domain/return_models.dart';
import '../domain/value_objects/money.dart';
import 'returns_repository.dart';

/// No-op returns backend for the in-memory demo mode.
class DemoReturnsRepository implements ReturnsRepository {
  int _seq = 1;
  final List<SalesReturnSummary> _returns = [];

  @override
  Future<List<SalesReturnSummary>> recentReturns({int limit = 50}) async {
    final sorted = [..._returns]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<ReturnableLine>> returnableLines(int orderId) async => const [];

  @override
  Future<SalesReturnSummary> createReturn({
    required int orderId,
    required List<ReturnLineInput> lines,
    required RefundMethod refundMethod,
    String? reason,
    int? userId,
  }) async {
    var total = Money.zero();
    for (final l in lines) {
      total = total.add(l.lineTotal);
    }
    final summary = SalesReturnSummary(
      id: _seq++,
      returnNumber: 'RET-DEMO-$_seq',
      posOrderId: orderId,
      refundMethod: refundMethod,
      totalAmount: total,
      createdAt: DateTime.now(),
    );
    _returns.add(summary);
    return summary;
  }
}
