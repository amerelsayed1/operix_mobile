import 'package:postgres/postgres.dart';

import '../domain/pos_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'pos_repository.dart';

class PostgresPosRepository implements PosRepository {
  PostgresPosRepository(this.database);

  final OperixDatabase database;

  @override
  bool get isPersistent => true;

  @override
  Future<List<PosProduct>> loadProducts() async {
    final conn = await database.connection();
    // Only sellable stock shows on the terminal — out-of-stock items are hidden
    // (they can't be sold and the checkout guard would reject them anyway).
    final result = await conn.execute('''
      SELECT id, sku, name, category, quantity_on_hand, unit_price
      FROM products
      WHERE is_active = TRUE AND quantity_on_hand > 0
      ORDER BY category ASC, name ASC
    ''');
    return result.map((row) {
      final map = row.toColumnMap();
      return PosProduct(
        id: _asInt(map['id']),
        sku: _asString(map['sku']),
        name: _asString(map['name']),
        category: _asString(map['category']),
        unitPrice: _asMoney(map['unit_price']),
        quantityOnHand: _asInt(map['quantity_on_hand']),
      );
    }).toList();
  }

  @override
  Future<PosShift?> activeShift(int cashierId) async {
    final conn = await database.connection();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, shift_number, cashier_id, cashier_name, opening_float,
               status, opened_at, closed_at, notes
        FROM pos_shifts
        WHERE status = 'open' AND cashier_id = @cashier_id
        ORDER BY opened_at DESC
        LIMIT 1
      '''),
      parameters: {'cashier_id': cashierId},
    );
    if (result.isEmpty) {
      return null;
    }
    return _shiftFromRow(result.first.toColumnMap());
  }

  @override
  Future<PosShift> openShift({
    required AppUser cashier,
    required Money openingFloat,
  }) async {
    final conn = await database.connection();
    // Sequence fetch + insert in one transaction so a crash can't burn a shift
    // number without a matching row.
    final result = await conn.runTx((session) async {
      final seq = await session.execute(
        "SELECT nextval('pos_shift_seq')::bigint AS seq",
      );
      final shiftNumber =
          'SH-${_asInt(seq.first.toColumnMap()['seq']).toString().padLeft(4, '0')}';

      return session.execute(
        Sql.named('''
          INSERT INTO pos_shifts (shift_number, cashier_id, cashier_name, opening_float, status)
          VALUES (@number, @cashier_id, @cashier_name, @opening_float, 'open')
          RETURNING id, shift_number, opened_at
        '''),
        parameters: {
          'number': shiftNumber,
          'cashier_id': cashier.id,
          'cashier_name': cashier.fullName,
          'opening_float': openingFloat.toStorageString(),
        },
      );
    });
    final map = result.first.toColumnMap();
    final shiftNumber = _asString(map['shift_number']);
    return PosShift(
      id: _asInt(map['id']),
      shiftNumber: shiftNumber,
      cashierId: cashier.id,
      cashierName: cashier.fullName,
      openingFloat: openingFloat,
      status: 'open',
      openedAt: _asDate(map['opened_at']),
    );
  }

  @override
  Future<PosShift> closeShift({
    required PosShift shift,
    required Money countedCash,
    String? notes,
  }) async {
    final conn = await database.connection();
    // Read the cash total and write the close-out in one transaction so a
    // concurrent sale on the same shift can't slip in between the SUM and the
    // UPDATE and leave expected_cash stale.
    final (expectedCash, difference, result) = await conn.runTx((
      session,
    ) async {
      final cashResult = await session.execute(
        Sql.named('''
          SELECT
            (SELECT COALESCE(SUM(p.amount), 0)
               FROM pos_order_payments p
               JOIN pos_orders o ON o.id = p.pos_order_id
               WHERE o.shift_id = @shift_id AND p.method = 'cash') AS cash_in,
            (SELECT COALESCE(SUM(o.change_amount), 0)
               FROM pos_orders o
               WHERE o.shift_id = @shift_id) AS change_out,
            (SELECT COALESCE(SUM(r.total_amount), 0)
               FROM sales_returns r
               WHERE r.shift_id = @shift_id AND r.refund_method = 'cash') AS refund_out
        '''),
        parameters: {'shift_id': shift.id},
      );
      final cashMap = cashResult.first.toColumnMap();
      final cashSales = _asMoney(cashMap['cash_in']);
      final changeGiven = _asMoney(cashMap['change_out']);
      final cashRefunds = _asMoney(cashMap['refund_out']);
      // Cash tendered enters the drawer; change handed back and cash refunds
      // paid out both leave it.
      final expected = shift.openingFloat
          .add(cashSales)
          .subtract(changeGiven)
          .subtract(cashRefunds);
      final diff = countedCash.subtract(expected);

      final updated = await session.execute(
        Sql.named('''
          UPDATE pos_shifts
          SET status = 'closed',
              expected_cash = @expected,
              counted_cash = @counted,
              cash_difference = @difference,
              notes = @notes,
              closed_at = NOW()
          WHERE id = @shift_id
          RETURNING closed_at
        '''),
        parameters: {
          'expected': expected.toStorageString(),
          'counted': countedCash.toStorageString(),
          'difference': diff.toStorageString(),
          'notes': notes,
          'shift_id': shift.id,
        },
      );
      return (expected, diff, updated);
    });

    return PosShift(
      id: shift.id,
      shiftNumber: shift.shiftNumber,
      cashierId: shift.cashierId,
      cashierName: shift.cashierName,
      openingFloat: shift.openingFloat,
      status: 'closed',
      openedAt: shift.openedAt,
      expectedCash: expectedCash,
      countedCash: countedCash,
      cashDifference: difference,
      closedAt: _asDate(result.first.toColumnMap()['closed_at']),
      notes: notes,
    );
  }

  @override
  Future<PosReceipt> checkout(CheckoutRequest request) async {
    final conn = await database.connection();
    try {
      return await conn.runTx((session) async {
        // Resolve GL accounts before drawing the receipt number so a misconfigured
        // chart of accounts can't burn a number from the sequence.
        final accounts = await _resolveAccounts(session, const [
          '1100', // Cash / drawer
          '4100', // Sales Revenue
          '2200', // Tax Payable (output VAT)
          '5100', // Cost of Goods Sold
          '1300', // Inventory
        ]);

        final seqResult = await session.execute(
          "SELECT nextval('pos_receipt_seq')::bigint AS seq",
        );
        final receiptNumber =
            'POS-${_asInt(seqResult.first.toColumnMap()['seq']).toString().padLeft(6, '0')}';

        final orderResult = await session.execute(
          Sql.named('''
            INSERT INTO pos_orders (
              receipt_number, shift_id, cashier_id, cashier_name, customer_name,
              subtotal, discount_amount, tax_amount, total_amount,
              paid_amount, change_amount, payment_status, status
            ) VALUES (
              @receipt_number, @shift_id, @cashier_id, @cashier_name, @customer_name,
              @subtotal, @discount, @tax, @total,
              @paid, @change, 'paid', 'completed'
            )
            RETURNING id, created_at
          '''),
          parameters: {
            'receipt_number': receiptNumber,
            'shift_id': request.shift.id,
            'cashier_id': request.cashier.id,
            'cashier_name': request.cashier.fullName,
            'customer_name': request.customerName,
            'subtotal': request.subtotal.toStorageString(),
            'discount': request.discount.toStorageString(),
            'tax': request.tax.toStorageString(),
            'total': request.total.toStorageString(),
            'paid': request.paidAmount.toStorageString(),
            'change': request.changeAmount.toStorageString(),
          },
        );
        final orderMap = orderResult.first.toColumnMap();
        final orderId = _asInt(orderMap['id']);
        final createdAt = _asDate(orderMap['created_at']);

        final receiptLines = <ReceiptLine>[];
        // Accumulate COGS from the live weighted-average cost relieved per line,
        // so the COGS/Inventory journal ties out to what inventory actually held.
        var cogs = Money.zero();
        for (final line in request.lines) {
          // Relieve stock first and read back the cost it was carried at, so the
          // order line records the exact cost basis (used for COGS and for an
          // accurate reversal if the line is later returned).
          final updated = await session.execute(
            Sql.named('''
              UPDATE products
              SET quantity_on_hand = quantity_on_hand - @quantity
              WHERE id = @product_id AND quantity_on_hand >= @quantity
              RETURNING cost_price
            '''),
            parameters: {
              'quantity': line.quantity,
              'product_id': line.product.id,
            },
          );
          if (updated.affectedRows == 0) {
            // Transaction rolls back automatically when we throw.
            throw InsufficientStockException(line.product.name);
          }
          final unitCost = Money.parse(
            updated.first.toColumnMap()['cost_price'],
          );
          cogs = cogs.add(unitCost.multiply(line.quantity));

          await session.execute(
            Sql.named('''
              INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price, unit_cost)
              VALUES (@order_id, @product_id, @name, @quantity, @unit_price, @unit_cost)
            '''),
            parameters: {
              'order_id': orderId,
              'product_id': line.product.id,
              'name': line.product.name,
              'quantity': line.quantity,
              'unit_price': line.product.unitPrice.toStorageString(),
              'unit_cost': unitCost.toStorageString(),
            },
          );

          // Record the stock movement for the audit log (negative = stock out).
          await session.execute(
            Sql.named('''
              INSERT INTO stock_movements
                (product_id, type, quantity, reference_type, reference_id)
              VALUES (@product_id, 'pos_sale', @quantity, 'pos_order', @order_id)
            '''),
            parameters: {
              'product_id': line.product.id,
              'quantity': -line.quantity,
              'order_id': orderId,
            },
          );

          receiptLines.add(
            ReceiptLine(
              name: line.product.name,
              sku: line.product.sku,
              quantity: line.quantity,
              unitPrice: line.product.unitPrice,
            ),
          );
        }

        for (final payment in request.payments) {
          await session.execute(
            Sql.named('''
              INSERT INTO pos_order_payments (pos_order_id, method, method_label, amount, reference)
              VALUES (@order_id, @method, @label, @amount, @reference)
            '''),
            parameters: {
              'order_id': orderId,
              'method': payment.method.wireValue,
              'label': payment.method == PaymentMethod.custom
                  ? payment.label
                  : null,
              'amount': payment.amount.toStorageString(),
              'reference': payment.reference,
            },
          );
        }

        // Post the sale to the GL so POS revenue, output VAT and COGS hit the
        // books like a sales invoice does. Cash POS sales settle in full at the
        // till, so the money leg debits Cash (1100):
        //   Dr Cash (total)        Cr Sales Revenue (net of discount)
        //                          Cr Tax Payable   (tax)
        //   Dr COGS (cost)         Cr Inventory     (cost)
        cogs = cogs.rounded();
        final revenue = request.subtotal.subtract(request.discount);
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
              @ref, 'pos_order', @source_id, 'sale_posting', @description,
              CURRENT_DATE, NOW(), 'posted'
            )
            RETURNING id
          '''),
          parameters: {
            'ref': reference,
            'source_id': orderId,
            'description': 'POS sale $receiptNumber',
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

        await postLine('1100', 'debit', request.total); // Cash / drawer
        await postLine('4100', 'credit', revenue); // Sales Revenue
        await postLine('2200', 'credit', request.tax); // Tax Payable
        await postLine('5100', 'debit', cogs); // COGS
        await postLine('1300', 'credit', cogs); // Inventory

        return PosReceipt(
          id: orderId,
          receiptNumber: receiptNumber,
          cashierName: request.cashier.fullName,
          createdAt: createdAt,
          lines: receiptLines,
          payments: request.payments,
          subtotal: request.subtotal,
          discount: request.discount,
          tax: request.tax,
          total: request.total,
          paidAmount: request.paidAmount,
          changeAmount: request.changeAmount,
          customerName: request.customerName,
        );
      });
    } on PosException {
      rethrow;
    } catch (error) {
      throw PosException('Could not save the order: $error');
    }
  }

  @override
  Future<List<PosOrderSummary>> recentOrders({
    int? shiftId,
    int limit = 50,
  }) async {
    final conn = await database.connection();
    final filter = shiftId == null ? '' : 'WHERE o.shift_id = @shift_id';
    final result = await conn.execute(
      Sql.named('''
        SELECT
          o.id,
          o.receipt_number,
          o.created_at,
          o.total_amount,
          o.status,
          COALESCE(SUM(i.quantity), 0)::int AS item_count,
          COALESCE((
            SELECT string_agg(DISTINCT pay.method, '+')
            FROM pos_order_payments pay
            WHERE pay.pos_order_id = o.id
          ), '') AS methods
        FROM pos_orders o
        LEFT JOIN pos_order_items i ON i.pos_order_id = o.id
        $filter
        GROUP BY o.id
        ORDER BY o.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'shift_id': ?shiftId, 'limit': limit},
    );

    return result.map((row) {
      final map = row.toColumnMap();
      return PosOrderSummary(
        id: _asInt(map['id']),
        receiptNumber: _asString(map['receipt_number']),
        createdAt: _asDate(map['created_at']),
        total: _asMoney(map['total_amount']),
        itemCount: _asInt(map['item_count']),
        paymentSummary: _asString(map['methods']),
        status: _asString(map['status']),
      );
    }).toList();
  }

  @override
  Future<PosReceipt> orderReceipt(int orderId) async {
    final conn = await database.connection();
    final headResult = await conn.execute(
      Sql.named('''
        SELECT id, receipt_number, cashier_name, customer_name, created_at,
               subtotal, discount_amount, tax_amount, total_amount,
               paid_amount, change_amount
        FROM pos_orders
        WHERE id = @id
      '''),
      parameters: {'id': orderId},
    );
    if (headResult.isEmpty) {
      throw const PosException('Order not found.');
    }
    final head = headResult.first.toColumnMap();

    final itemsResult = await conn.execute(
      Sql.named('''
        SELECT i.name, COALESCE(p.sku, '') AS sku, i.quantity, i.unit_price
        FROM pos_order_items i
        LEFT JOIN products p ON p.id = i.product_id
        WHERE i.pos_order_id = @id
        ORDER BY i.id ASC
      '''),
      parameters: {'id': orderId},
    );
    final lines = itemsResult.map((row) {
      final map = row.toColumnMap();
      return ReceiptLine(
        name: _asString(map['name']),
        sku: _asString(map['sku']),
        quantity: _asInt(map['quantity']),
        unitPrice: _asMoney(map['unit_price']),
      );
    }).toList();

    final paymentsResult = await conn.execute(
      Sql.named('''
        SELECT method, method_label, amount, reference
        FROM pos_order_payments
        WHERE pos_order_id = @id
        ORDER BY id ASC
      '''),
      parameters: {'id': orderId},
    );
    final payments = paymentsResult.map((row) {
      final map = row.toColumnMap();
      return PosPayment(
        method: PaymentMethodX.fromWire(_asString(map['method'])),
        amount: _asMoney(map['amount']),
        label: map['method_label'] as String?,
        reference: map['reference'] as String?,
      );
    }).toList();

    return PosReceipt(
      id: _asInt(head['id']),
      receiptNumber: _asString(head['receipt_number']),
      cashierName: _asString(head['cashier_name']),
      createdAt: _asDate(head['created_at']),
      lines: lines,
      payments: payments,
      subtotal: _asMoney(head['subtotal']),
      discount: _asMoney(head['discount_amount']),
      tax: _asMoney(head['tax_amount']),
      total: _asMoney(head['total_amount']),
      paidAmount: _asMoney(head['paid_amount']),
      changeAmount: _asMoney(head['change_amount']),
      customerName: head['customer_name'] as String?,
    );
  }

  PosShift _shiftFromRow(Map<String, dynamic> map) {
    return PosShift(
      id: _asInt(map['id']),
      shiftNumber: _asString(map['shift_number']),
      cashierId: _asInt(map['cashier_id']),
      cashierName: _asString(map['cashier_name']),
      openingFloat: _asMoney(map['opening_float']),
      status: _asString(map['status']),
      openedAt: _asDate(map['opened_at']),
      closedAt: map['closed_at'] == null ? null : _asDate(map['closed_at']),
      notes: map['notes'] as String?,
    );
  }

  /// Resolves each GL [codes] entry to its account id, throwing loudly if any is
  /// missing so the sale rolls back before a receipt number is drawn.
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
        throw PosException(
          'GL account "$code" is not configured; cannot post the sale.',
        );
      }
    }
    return map;
  }

  String _asString(Object? value) => value?.toString() ?? '';

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Money _asMoney(Object? value) => Money.parse(value);

  DateTime _asDate(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
