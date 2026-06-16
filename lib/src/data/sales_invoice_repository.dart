import '../domain/sales_invoice_models.dart';

class SalesInvoiceException implements Exception {
  const SalesInvoiceException(this.message);
  final String message;
  @override
  String toString() => 'SalesInvoiceException: $message';
}

abstract interface class SalesInvoiceRepository {
  /// Creates and posts a sales invoice: persists the invoice + line items,
  /// relieves stock, and writes the balanced GL journal entry.
  Future<SalesInvoice> create(SalesInvoiceDraft draft);
}
