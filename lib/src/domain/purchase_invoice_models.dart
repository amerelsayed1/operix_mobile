import 'value_objects/money.dart';

/// A single line on a purchase-invoice draft. For purchases the [unitPrice] is
/// the cost paid to the supplier (it is weighted into the product's average
/// cost). [salePrice] is an optional new selling price to set on the product
/// while receiving it — a pricing convenience that updates the product catalogue
/// only; it never affects the purchase totals, tax, or GL (a purchase is valued
/// at cost). When null, the product's existing selling price is left untouched.
class PurchaseInvoiceLineDraft {
  const PurchaseInvoiceLineDraft({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.salePrice,
  });

  final int? productId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money? salePrice;

  Money get lineTotal => unitPrice.multiply(quantity);
}

/// Everything needed to create a posted purchase (supplier) invoice.
class PurchaseInvoiceDraft {
  const PurchaseInvoiceDraft({
    required this.supplierId,
    required this.supplierName,
    required this.issueDate,
    required this.lines,
    this.taxRate = 14,
  });

  final int? supplierId;
  final String supplierName;
  final DateTime issueDate;
  final List<PurchaseInvoiceLineDraft> lines;
  final double taxRate;

  Money get subtotal =>
      lines.fold(Money.zero(), (sum, l) => sum.add(l.lineTotal));

  Money get taxAmount => subtotal.percentage(taxRate.toString());

  Money get total => subtotal.add(taxAmount);
}

/// A persisted purchase invoice (the result of creating one).
class PurchaseInvoice {
  const PurchaseInvoice({
    required this.id,
    required this.number,
    required this.supplierName,
    required this.issueDate,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.status,
  });

  final int id;
  final String number;
  final String supplierName;
  final DateTime issueDate;
  final Money subtotal;
  final Money taxAmount;
  final Money total;
  final String status;
}
