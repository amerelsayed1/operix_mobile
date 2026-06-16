// Domain models for authentication, the point-of-sale flow, cashier shifts,
// and receipts. Kept free of Flutter / database imports so they can be shared
// across the UI, controllers, and repository implementations.
//
// Monetary fields use the [Money] value object (mirror of the cloud's
// decimal(15,2) + bcmath) — never double — so totals match the cloud exactly.

import 'value_objects/money.dart';

/// A local application user that can sign in to the desktop client.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String username;
  final String fullName;
  final String role;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return username.isEmpty ? '?' : username[0].toUpperCase();
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A sellable product as shown in the POS grid.
class PosProduct {
  const PosProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.quantityOnHand,
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final Money unitPrice;
  final int quantityOnHand;

  bool get inStock => quantityOnHand > 0;

  PosProduct copyWith({int? quantityOnHand}) {
    return PosProduct(
      id: id,
      sku: sku,
      name: name,
      category: category,
      unitPrice: unitPrice,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
    );
  }
}

/// A line in the working cart.
class CartLine {
  CartLine({required this.product, required this.quantity});

  final PosProduct product;
  int quantity;

  Money get lineTotal => product.unitPrice.multiply(quantity).rounded();
}

/// Supported tender types.
enum PaymentMethod { cash, card, custom }

extension PaymentMethodX on PaymentMethod {
  String get wireValue => name; // cash | card | custom
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.custom:
        return 'Custom';
    }
  }

  static PaymentMethod fromWire(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.custom,
    );
  }
}

/// A single tender applied to an order. [amount] is the portion of the order
/// total settled by this method (i.e. already net of any change handed back),
/// so summing cash payments gives the net cash added to the drawer.
class PosPayment {
  const PosPayment({
    required this.method,
    required this.amount,
    this.label,
    this.reference,
  });

  final PaymentMethod method;
  final Money amount;
  final String? label; // free text for custom methods
  final String? reference;

  String get displayLabel {
    if (method == PaymentMethod.custom) {
      final custom = label?.trim();
      return (custom == null || custom.isEmpty) ? 'Custom' : custom;
    }
    return method.label;
  }
}

/// Everything needed to persist a completed sale.
class CheckoutRequest {
  CheckoutRequest({
    required this.cashier,
    required this.shift,
    required this.lines,
    required this.payments,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    this.customerName,
  });

  final AppUser cashier;
  final PosShift shift;
  final List<CartLine> lines;
  final List<PosPayment> payments;
  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money total;
  final Money paidAmount;
  final Money changeAmount;
  final String? customerName;
}

/// A persisted line on a receipt.
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final String sku;
  final int quantity;
  final Money unitPrice;

  Money get lineTotal => unitPrice.multiply(quantity).rounded();
}

/// A fully persisted order, used for the printable receipt preview.
class PosReceipt {
  const PosReceipt({
    required this.id,
    required this.receiptNumber,
    required this.cashierName,
    required this.createdAt,
    required this.lines,
    required this.payments,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    this.customerName,
  });

  final int id;
  final String receiptNumber;
  final String cashierName;
  final DateTime createdAt;
  final List<ReceiptLine> lines;
  final List<PosPayment> payments;
  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money total;
  final Money paidAmount;
  final Money changeAmount;
  final String? customerName;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
}

/// Lightweight row for the sales-history list.
class PosOrderSummary {
  const PosOrderSummary({
    required this.id,
    required this.receiptNumber,
    required this.createdAt,
    required this.total,
    required this.itemCount,
    required this.paymentSummary,
    required this.status,
  });

  final int id;
  final String receiptNumber;
  final DateTime createdAt;
  final Money total;
  final int itemCount;
  final String paymentSummary;
  final String status;
}

/// A cashier shift. Cash is reconciled at close: expected drawer cash is the
/// opening float plus net cash sales for the shift.
class PosShift {
  const PosShift({
    required this.id,
    required this.shiftNumber,
    required this.cashierId,
    required this.cashierName,
    required this.openingFloat,
    required this.status,
    required this.openedAt,
    this.expectedCash,
    this.countedCash,
    this.cashDifference,
    this.closedAt,
    this.notes,
  });

  final int id;
  final String shiftNumber;
  final int cashierId;
  final String cashierName;
  final Money openingFloat;
  final String status; // open | closed
  final DateTime openedAt;
  final Money? expectedCash;
  final Money? countedCash;
  final Money? cashDifference;
  final DateTime? closedAt;
  final String? notes;

  bool get isOpen => status == 'open';
}
