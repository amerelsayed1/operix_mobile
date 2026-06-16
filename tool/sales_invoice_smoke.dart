// Throwaway check of PostgresSalesInvoiceRepository against the live DB.
// Run: dart run tool/sales_invoice_smoke.dart
// ignore_for_file: avoid_print
import 'package:operix_mobile/src/config/database_config.dart';
import 'package:operix_mobile/src/data/operix_database.dart';
import 'package:operix_mobile/src/data/postgres_sales_invoice_repository.dart';
import 'package:operix_mobile/src/domain/sales_invoice_models.dart';
import 'package:operix_mobile/src/domain/value_objects/money.dart';

Future<void> main() async {
  final db = OperixDatabase(DatabaseConfig.fromEnvironment());
  final repo = PostgresSalesInvoiceRepository(db);

  final invoice = await repo.create(
    SalesInvoiceDraft(
      clientId: null,
      clientName: 'Walk-in client',
      issueDate: DateTime.now(),
      taxRate: 14,
      lines: [
        SalesInvoiceLineDraft(
          productId: null,
          name: 'Consulting hours',
          quantity: 3,
          unitPrice: Money.of('100'),
          costPrice: Money.of('40'),
        ),
        SalesInvoiceLineDraft(
          productId: null,
          name: 'Setup fee',
          quantity: 1,
          unitPrice: Money.of('200'),
          costPrice: Money.of('0'),
        ),
      ],
    ),
  );
  print(
    '> created ${invoice.number} id=${invoice.id} '
    'subtotal=${invoice.subtotal} tax=${invoice.taxAmount} total=${invoice.total}',
  );

  final conn = await db.connection();
  final je = await conn.execute('''
    SELECT je.reference_no,
           SUM(CASE WHEN l.line_type='debit'  THEN l.amount ELSE 0 END) AS debits,
           SUM(CASE WHEN l.line_type='credit' THEN l.amount ELSE 0 END) AS credits
    FROM journal_entries je
    JOIN journal_entry_lines l ON l.journal_entry_id = je.id
    WHERE je.source_type='sales_invoice' AND je.source_id=${invoice.id}
    GROUP BY je.reference_no
  ''');
  for (final row in je) {
    final m = row.toColumnMap();
    print(
      '> GL ${m['reference_no']}: debits=${m['debits']} credits=${m['credits']} '
      '${m['debits'] == m['credits'] ? 'BALANCED ✓' : 'UNBALANCED ✗'}',
    );
  }

  await db.close();
  print('DONE');
}
