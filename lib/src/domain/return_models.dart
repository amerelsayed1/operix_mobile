// Sales-return domain models. A return is raised against a past POS order:
// selected lines are restocked and a refund is recorded. Free of Flutter / DB
// imports; amounts use [Money].

import 'value_objects/money.dart';

/// How the customer is refunded.
enum RefundMethod { cash, credit }

extension RefundMethodX on RefundMethod {
  String get wire => name; // cash | credit
  String get label =>
      this == RefundMethod.cash ? 'Cash refund' : 'Store credit';
  static RefundMethod fromWire(String value) => RefundMethod.values.firstWhere(
    (m) => m.name == value,
    orElse: () => RefundMethod.cash,
  );
}

/// A line on the original order that can still be returned.
class ReturnableLine {
  const ReturnableLine({
    required this.orderItemId,
    required this.name,
    required this.sku,
    required this.soldQuantity,
    required this.returnedQuantity,
    required this.unitPrice,
    this.productId,
  });

  /// Id of the originating `pos_order_items` row. Returnable quantity is tracked
  /// per order line (not bucketed by product/name) so two lines that share a
  /// product can't draw down each other's returnable pool.
  final int orderItemId;
  final int? productId;
  final String name;
  final String sku;
  final int soldQuantity;
  final int returnedQuantity;
  final Money unitPrice;

  /// Quantity still available to return.
  int get available => soldQuantity - returnedQuantity;
}

/// One selected return line submitted to the repository.
class ReturnLineInput {
  const ReturnLineInput({
    required this.orderItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.productId,
  });

  /// Id of the originating `pos_order_items` row this return is drawn from.
  final int orderItemId;
  final int? productId;
  final String name;
  final int quantity;
  final Money unitPrice;

  Money get lineTotal => unitPrice.multiply(quantity).rounded();
}

/// Result of a processed return.
class SalesReturnSummary {
  const SalesReturnSummary({
    required this.id,
    required this.returnNumber,
    required this.refundMethod,
    required this.totalAmount,
    required this.createdAt,
    this.posOrderId,
  });

  final int id;
  final String returnNumber;
  final int? posOrderId;
  final RefundMethod refundMethod;
  final Money totalAmount;
  final DateTime createdAt;
}
