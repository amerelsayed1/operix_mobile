import 'value_objects/money.dart';

/// A single line on a sales-invoice draft. [costPrice] is captured so the GL
/// posting can record COGS / inventory relief.
class SalesInvoiceLineDraft {
  const SalesInvoiceLineDraft({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
  });

  final int? productId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money costPrice;

  Money get lineTotal => unitPrice.multiply(quantity);
  Money get lineCost => costPrice.multiply(quantity);
}

/// Everything needed to create a posted sales invoice.
class SalesInvoiceDraft {
  const SalesInvoiceDraft({
    required this.clientId,
    required this.clientName,
    required this.issueDate,
    required this.lines,
    this.taxRate = 14,
  });

  final int? clientId;
  final String clientName;
  final DateTime issueDate;
  final List<SalesInvoiceLineDraft> lines;

  /// VAT percentage applied to the subtotal (e.g. 14 for Egypt).
  final double taxRate;

  Money get subtotal =>
      lines.fold(Money.zero(), (sum, l) => sum.add(l.lineTotal));

  Money get taxAmount => subtotal.percentage(taxRate.toString());

  Money get total => subtotal.add(taxAmount);

  Money get cogs => lines.fold(Money.zero(), (sum, l) => sum.add(l.lineCost));
}

/// A persisted sales invoice (the result of creating one).
class SalesInvoice {
  const SalesInvoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.issueDate,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.status,
  });

  final int id;
  final String number;
  final String clientName;
  final DateTime issueDate;
  final Money subtotal;
  final Money taxAmount;
  final Money total;
  final String status;
}
