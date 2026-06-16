import 'package:postgres/postgres.dart';

import '../domain/sales_invoice_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'sales_invoice_repository.dart';

class PostgresSalesInvoiceRepository implements SalesInvoiceRepository {
  PostgresSalesInvoiceRepository(this.database);

  final OperixDatabase database;

  @override
  Future<SalesInvoice> create(SalesInvoiceDraft draft) async {
    if (draft.lines.isEmpty) {
      throw const SalesInvoiceException(
        'Add at least one item to the invoice.',
      );
    }

    final subtotal = draft.subtotal;
    final tax = draft.taxAmount;
    final total = draft.total;

    final conn = await database.connection();
    // One transaction so the invoice, line items, stock relief, and GL journal
    // either all land or none do.
    return conn.runTx((session) async {
      // Resolve GL accounts and confirm stock availability *before* drawing the
      // invoice number, so a foreseeable failure (missing account, short stock)
      // rolls back without burning a number from the sequence and leaving a
      // permanent gap (a compliance problem under Egypt ETA / Saudi ZATCA).
      final accounts = await _resolveAccounts(session, const [
        '1200', // Accounts Receivable
        '4100', // Sales Revenue
        '2200', // Tax Payable (output VAT)
        '5100', // Cost of Goods Sold
        '1300', // Inventory
      ]);
      await _assertStockAvailable(session, draft.lines);

      final numberResult = await session.execute(
        "SELECT 'INV-' || LPAD(nextval('sales_invoice_seq')::text, 6, '0') AS num",
      );
      final number = numberResult.first.toColumnMap()['num'] as String;

      final invoiceResult = await session.execute(
        Sql.named('''
          INSERT INTO sales_invoices (
            invoice_number, client_id, status, issue_date,
            subtotal, tax_amount, total_amount
          ) VALUES (
            @number, @client_id, 'posted', @issue_date,
            @subtotal, @tax, @total
          )
          RETURNING id
        '''),
        parameters: {
          'number': number,
          'client_id': draft.clientId,
          'issue_date': draft.issueDate,
          'subtotal': subtotal.toStorageString(),
          'tax': tax.toStorageString(),
          'total': total.toStorageString(),
        },
      );
      final invoiceId = _asInt(invoiceResult.first.toColumnMap()['id']);

      // Accumulate COGS from the *live* weighted-average cost relieved on each
      // line (not a cost snapshotted in the UI), so the Inventory credit always
      // matches what the Inventory account actually held.
      var cogs = Money.zero();
      for (final line in draft.lines) {
        var unitCost = Money.zero();

        if (line.productId != null) {
          // Relieve stock and read back the cost it was carried at in the same
          // statement. Only decrement when enough is on hand, failing the whole
          // transaction otherwise so inventory can never go negative.
          final stockResult = await session.execute(
            Sql.named(
              'UPDATE products SET quantity_on_hand = quantity_on_hand - @quantity '
              'WHERE id = @product AND quantity_on_hand >= @quantity '
              'RETURNING cost_price',
            ),
            parameters: {'quantity': line.quantity, 'product': line.productId},
          );
          if (stockResult.affectedRows == 0) {
            throw SalesInvoiceException(
              'Not enough stock to invoice "${line.name}".',
            );
          }
          unitCost = Money.parse(stockResult.first.toColumnMap()['cost_price']);
          cogs = cogs.add(unitCost.multiply(line.quantity));

          await session.execute(
            Sql.named('''
              INSERT INTO stock_movements
                (product_id, type, quantity, reference_type, reference_id)
              VALUES (@product, 'sales_invoice', @quantity, 'sales_invoice', @invoice)
            '''),
            parameters: {
              'product': line.productId,
              'quantity': -line.quantity,
              'invoice': invoiceId,
            },
          );
        }

        await session.execute(
          Sql.named('''
            INSERT INTO sales_invoice_items (
              sales_invoice_id, product_id, name, quantity, unit_price, line_total, unit_cost
            ) VALUES (@invoice, @product, @name, @quantity, @unit_price, @line_total, @unit_cost)
          '''),
          parameters: {
            'invoice': invoiceId,
            'product': line.productId,
            'name': line.name,
            'quantity': line.quantity,
            'unit_price': line.unitPrice.toStorageString(),
            'line_total': line.lineTotal.toStorageString(),
            'unit_cost': unitCost.toStorageString(),
          },
        );
      }
      cogs = cogs.rounded();

      // Balanced GL journal entry mirroring a standard sales posting:
      //   Dr Accounts Receivable (total)   Cr Sales Revenue (subtotal)
      //                                     Cr Tax Payable   (tax)
      //   Dr COGS (cost)                    Cr Inventory     (cost)
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
            @ref, 'sales_invoice', @source_id, 'invoice_posting', @description,
            @date, NOW(), 'posted'
          )
          RETURNING id
        '''),
        parameters: {
          'ref': reference,
          'source_id': invoiceId,
          'description': 'Sales invoice $number',
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

      await postLine('1200', 'debit', total); // Accounts Receivable
      await postLine('4100', 'credit', subtotal); // Sales Revenue
      await postLine('2200', 'credit', tax); // Tax Payable
      await postLine('5100', 'debit', cogs); // COGS
      await postLine('1300', 'credit', cogs); // Inventory

      return SalesInvoice(
        id: invoiceId,
        number: number,
        clientName: draft.clientName,
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
        throw SalesInvoiceException(
          'GL account "$code" is not configured; cannot post invoice.',
        );
      }
    }
    return map;
  }

  /// Verifies every stock-backed line can be fully relieved, aggregating across
  /// duplicate product lines, *before* a number is drawn. The per-line decrement
  /// still guards atomically against a concurrent sale; this just keeps the
  /// common shortfall from burning an invoice number.
  Future<void> _assertStockAvailable(
    Session session,
    List<SalesInvoiceLineDraft> lines,
  ) async {
    final required = <int, int>{};
    final names = <int, String>{};
    for (final line in lines) {
      final id = line.productId;
      if (id == null) continue;
      required[id] = (required[id] ?? 0) + line.quantity;
      names[id] = line.name;
    }
    if (required.isEmpty) return;

    final result = await session.execute(
      Sql.named(
        'SELECT id, quantity_on_hand FROM products WHERE id = ANY(@ids)',
      ),
      parameters: {'ids': required.keys.toList()},
    );
    final onHand = <int, int>{};
    for (final row in result) {
      final m = row.toColumnMap();
      onHand[_asInt(m['id'])] = _asInt(m['quantity_on_hand']);
    }
    for (final entry in required.entries) {
      if ((onHand[entry.key] ?? 0) < entry.value) {
        throw SalesInvoiceException(
          'Not enough stock to invoice "${names[entry.key]}".',
        );
      }
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
