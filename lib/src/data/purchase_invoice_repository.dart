import '../domain/purchase_invoice_models.dart';

class PurchaseInvoiceException implements Exception {
  const PurchaseInvoiceException(this.message);
  final String message;
  @override
  String toString() => 'PurchaseInvoiceException: $message';
}

abstract interface class PurchaseInvoiceRepository {
  /// Creates and posts a purchase invoice: persists the invoice + line items,
  /// receives stock (and updates last cost), and writes the balanced GL journal.
  Future<PurchaseInvoice> create(PurchaseInvoiceDraft draft);
}
