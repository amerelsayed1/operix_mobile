import '../domain/purchase_invoice_models.dart';
import 'purchase_invoice_repository.dart';

/// In-memory purchase invoices for when PostgreSQL is not configured. Nothing is
/// persisted; it validates the draft and echoes back a posted invoice.
class DemoPurchaseInvoiceRepository implements PurchaseInvoiceRepository {
  int _seq = 1;

  @override
  Future<PurchaseInvoice> create(PurchaseInvoiceDraft draft) async {
    if (draft.lines.isEmpty) {
      throw const PurchaseInvoiceException(
        'Add at least one item to the invoice.',
      );
    }
    final id = _seq++;
    return PurchaseInvoice(
      id: id,
      number: 'PINV-${id.toString().padLeft(6, '0')}',
      supplierName: draft.supplierName,
      issueDate: draft.issueDate,
      subtotal: draft.subtotal,
      taxAmount: draft.taxAmount,
      total: draft.total,
      status: 'posted',
    );
  }
}
