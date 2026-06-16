import 'package:postgres/postgres.dart';

import '../domain/purchase_invoice_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'purchase_invoice_repository.dart';

class PostgresPurchaseInvoiceRepository implements PurchaseInvoiceRepository {
  PostgresPurchaseInvoiceRepository(this.database);

  final OperixDatabase database;

  @override
  Future<PurchaseInvoice> create(PurchaseInvoiceDraft draft) async {
    if (draft.lines.isEmpty) {
      throw const PurchaseInvoiceException(
        'Add at least one item to the invoice.',
      );
    }

    final subtotal = draft.subtotal;
    final tax = draft.taxAmount;
    final total = draft.total;

    final conn = await database.connection();
    // One transaction so the invoice, line items, stock receipt, and GL journal
    // either all land or none do.
    return conn.runTx((session) async {
      // Resolve every GL account we will post to *before* drawing the invoice
      // number, so a misconfigured chart of accounts fails without burning a
      // number from the sequence (which would leave a permanent gap — a
      // compliance problem under Egypt ETA / Saudi ZATCA).
      final accounts = await _resolveAccounts(session, const [
        '1300', // Inventory
        '1400', // Input VAT (recoverable)
        '2100', // Accounts Payable
      ]);

      final numberResult = await session.execute(
        "SELECT 'PINV-' || LPAD(nextval('supplier_invoice_seq')::text, 6, '0') AS num",
      );
      final number = numberResult.first.toColumnMap()['num'] as String;

      final invoiceResult = await session.execute(
        Sql.named('''
          INSERT INTO supplier_invoices (
            invoice_number, supplier_id, status, issue_date,
            subtotal, tax_amount, total_amount
          ) VALUES (
            @number, @supplier_id, 'posted', @issue_date,
            @subtotal, @tax, @total
          )
          RETURNING id
        '''),
        parameters: {
          'number': number,
          'supplier_id': draft.supplierId,
          'issue_date': draft.issueDate,
          'subtotal': subtotal.toStorageString(),
          'tax': tax.toStorageString(),
          'total': total.toStorageString(),
        },
      );
      final invoiceId = _asInt(invoiceResult.first.toColumnMap()['id']);

      for (final line in draft.lines) {
        await session.execute(
          Sql.named('''
            INSERT INTO supplier_invoice_items (
              supplier_invoice_id, product_id, name, quantity, unit_price, line_total
            ) VALUES (@invoice, @product, @name, @quantity, @unit_price, @line_total)
          '''),
          parameters: {
            'invoice': invoiceId,
            'product': line.productId,
            'name': line.name,
            'quantity': line.quantity,
            'unit_price': line.unitPrice.toStorageString(),
            'line_total': line.lineTotal.toStorageString(),
          },
        );

        if (line.productId != null) {
          // Receive stock and roll the product's cost forward using the moving
          // weighted-average method (IAS 2 compliant). Overwriting with the last
          // purchase price would let the Inventory control account drift away
          // from the value actually capitalised and could drive COGS — and the
          // Inventory balance — negative. The right-hand side sees the pre-update
          // quantity/cost, so this averages old stock against the new receipt.
          //
          // The optional sale price updates the product's catalogue selling
          // price in passing (COALESCE leaves it unchanged when not supplied).
          // It is a pricing convenience only — it does NOT enter the purchase
          // subtotal/tax/total or the GL, which are valued at cost.
          await session.execute(
            Sql.named('''
              UPDATE products
              SET quantity_on_hand = quantity_on_hand + @quantity,
                  cost_price = CASE
                    WHEN quantity_on_hand + @quantity <= 0 THEN @unit_price::numeric
                    ELSE round(
                      (quantity_on_hand * cost_price + @quantity * @unit_price::numeric)
                        / (quantity_on_hand + @quantity), 2)
                  END,
                  unit_price = COALESCE(@sale_price::numeric, unit_price)
              WHERE id = @product
            '''),
            parameters: {
              'quantity': line.quantity,
              'unit_price': line.unitPrice.toStorageString(),
              'sale_price': line.salePrice?.toStorageString(),
              'product': line.productId,
            },
          );
          await session.execute(
            Sql.named('''
              INSERT INTO stock_movements
                (product_id, type, quantity, reference_type, reference_id)
              VALUES (@product, 'purchase_invoice', @quantity, 'supplier_invoice', @invoice)
            '''),
            parameters: {
              'product': line.productId,
              'quantity': line.quantity,
              'invoice': invoiceId,
            },
          );
        }
      }

      // Balanced GL journal entry mirroring a standard purchase posting:
      //   Dr Inventory (subtotal)   Dr Input VAT (recoverable)
      //                             Cr Accounts Payable (total)
      final refResult = await session.execute(
        "SELECT 'JE-' || LPAD(nextval('journal_entry_seq')::text, 6, '0') AS ref",
      );
      final reference = refResult.first.toColumnMap()['ref'] as String;
      final entryResult = await session.execute(
        Sql.named('''
          INSERT INTO journal_entries (
            reference_no, source_type, source_id, entry_type, description,
            transaction_date, posted_at, status
          ) VALUES (
            @ref, 'supplier_invoice', @source_id, 'invoice_posting', @description,
            @date, NOW(), 'posted'
          )
          RETURNING id
        '''),
        parameters: {
          'ref': reference,
          'source_id': invoiceId,
          'description': 'Purchase invoice $number',
          'date': draft.issueDate,
        },
      );
      final entryId = _asInt(entryResult.first.toColumnMap()['id']);

      Future<void> postLine(String code, String type, Money amount) async {
        if (!amount.isPositive) return;
        await session.execute(
          Sql.named('''
            INSERT INTO journal_entry_lines
              (journal_entry_id, gl_account_id, line_type, amount)
            VALUES (@entry, @account, @type, @amount)
          '''),
          parameters: {
            'entry': entryId,
            'account': accounts[code],
            'type': type,
            'amount': amount.toStorageString(),
          },
        );
      }

      await postLine('1300', 'debit', subtotal); // Inventory
      await postLine('1400', 'debit', tax); // Input VAT (recoverable)
      await postLine('2100', 'credit', total); // Accounts Payable

      return PurchaseInvoice(
        id: invoiceId,
        number: number,
        supplierName: draft.supplierName,
        issueDate: draft.issueDate,
        subtotal: subtotal,
        taxAmount: tax,
        total: total,
        status: 'posted',
      );
    });
  }

  /// Resolves each GL [codes] entry to its account id, throwing loudly if any is
  /// missing so the whole posting rolls back before a sequence number is drawn.
  Future<Map<String, int>> _resolveAccounts(
    Session session,
    List<String> codes,
  ) async {
    final result = await session.execute(
      Sql.named('SELECT code, id FROM gl_accounts WHERE code = ANY(@codes)'),
      parameters: {'codes': codes},
    );
    final map = <String, int>{};
    for (final row in result) {
      final m = row.toColumnMap();
      map[m['code'] as String] = _asInt(m['id']);
    }
    for (final code in codes) {
      if (!map.containsKey(code)) {
        throw PurchaseInvoiceException(
          'GL account "$code" is not configured; cannot post invoice.',
        );
      }
    }
    return map;
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
