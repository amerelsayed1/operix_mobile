import '../domain/sales_invoice_models.dart';
import 'sales_invoice_repository.dart';

/// In-memory sales invoices for when PostgreSQL is not configured. Nothing is
/// persisted; it just validates the draft and echoes back a posted invoice.
class DemoSalesInvoiceRepository implements SalesInvoiceRepository {
  int _seq = 1;

  @override
  Future<SalesInvoice> create(SalesInvoiceDraft draft) async {
    if (draft.lines.isEmpty) {
      throw const SalesInvoiceException(
        'Add at least one item to the invoice.',
      );
    }
    final id = _seq++;
    return SalesInvoice(
      id: id,
      number: 'INV-${id.toString().padLeft(6, '0')}',
      clientName: draft.clientName,
      issueDate: draft.issueDate,
      subtotal: draft.subtotal,
      taxAmount: draft.taxAmount,
      total: draft.total,
      status: 'posted',
    );
  }
}
