import '../domain/return_models.dart';

class ReturnException implements Exception {
  const ReturnException(this.message);
  final String message;
  @override
  String toString() => 'ReturnException: $message';
}

/// Creates sales returns against POS orders and reports what is still returnable.
abstract interface class ReturnsRepository {
  /// Most recent sales returns, newest first.
  Future<List<SalesReturnSummary>> recentReturns({int limit = 50});

  /// The lines of [orderId] that can still be returned (net of prior returns).
  Future<List<ReturnableLine>> returnableLines(int orderId);

  /// Processes a return: records it, restocks the items, logs the movements.
  /// Throws [ReturnException] on validation failure.
  Future<SalesReturnSummary> createReturn({
    required int orderId,
    required List<ReturnLineInput> lines,
    required RefundMethod refundMethod,
    String? reason,
    int? userId,
  });
}
