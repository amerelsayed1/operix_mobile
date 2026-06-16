import 'package:postgres/postgres.dart';

import '../domain/return_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'returns_repository.dart';

class PostgresReturnsRepository implements ReturnsRepository {
  PostgresReturnsRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<SalesReturnSummary>> recentReturns({int limit = 50}) async {
    final conn = await database.connection();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, return_number, pos_order_id, refund_method, total_amount,
               created_at
        FROM sales_returns
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );
    return result.map((row) {
      final m = row.toColumnMap();
      return SalesReturnSummary(
        id: _asInt(m['id']),
        returnNumber: m['return_number']?.toString() ?? '',
        posOrderId: m['pos_order_id'] == null
            ? null
            : _asInt(m['pos_order_id']),
        refundMethod: RefundMethodX.fromWire(
          m['refund_method']?.toString() ?? 'cash',
        ),
        totalAmount: Money.parse(m['total_amount']),
        createdAt: _asDate(m['created_at']),
      );
    }).toList();
  }

  @override
  Future<List<ReturnableLine>> returnableLines(int orderId) async {
    final conn = await database.connection();
    final result = await conn.execute(
      Sql.named('''
        SELECT i.id AS order_item_id,
               i.product_id,
               i.name,
               COALESCE(p.sku, '') AS sku,
               i.quantity AS sold,
               i.unit_price,
               COALESCE((
                 SELECT SUM(ri.quantity)
                 FROM sales_return_items ri
                 WHERE ri.pos_order_item_id = i.id
               ), 0)::int AS returned
        FROM pos_order_items i
        LEFT JOIN products p ON p.id = i.product_id
        WHERE i.pos_order_id = @order_id
        ORDER BY i.id ASC
      '''),
      parameters: {'order_id': orderId},
    );
    return result.map((row) {
      final m = row.toColumnMap();
      return ReturnableLine(
        orderItemId: _asInt(m['order_item_id']),
        productId: m['product_id'] == null ? null : _asInt(m['product_id']),
        name: m['name']?.toString() ?? '',
        sku: m['sku']?.toString() ?? '',
        soldQuantity: _asInt(m['sold']),
        returnedQuantity: _asInt(m['returned']),
        unitPrice: Money.parse(m['unit_price']),
      );
    }).toList();
  }

  @override
  Future<SalesReturnSummary> createReturn({
    required int orderId,
    required List<ReturnLineInput> lines,
    required RefundMethod refundMethod,
    String? reason,
    int? userId,
  }) async {
    final selected = lines.where((l) => l.quantity > 0).toList();
    if (selected.isEmpty) {
      throw const ReturnException('Select at least one item to return.');
    }

    final conn = await database.connection();
    try {
      return await conn.runTx((session) async {
        // Resolve GL accounts before drawing the return number so a misconfigured
        // chart of accounts rolls back without burning a sequence number.
        final accounts = await _resolveAccounts(session, const [
          '4100', // Sales Revenue (reversed)
          '2200', // Tax Payable (reversed)
          '5100', // Cost of Goods Sold (reversed)
          '1300', // Inventory (restored)
          '1100', // Cash (cash refund)
          '1200', // Accounts Receivable (store credit)
        ]);

        // Re-validate returnable quantities inside the transaction, keyed by the
        // exact order line so sibling lines can't over-draw each other's pool.
        final available = await _availableMap(session, orderId);
        var netTotal = Money.zero();
        for (final line in selected) {
          final canReturn = available[line.orderItemId] ?? 0;
          if (line.quantity > canReturn) {
            throw ReturnException(
              'Cannot return ${line.quantity} × "${line.name}" — only $canReturn left.',
            );
          }
          netTotal = netTotal.add(line.lineTotal);
        }
        netTotal = netTotal.rounded();

        // Reverse the sale's components at their original basis: the captured
        // per-line cost (for COGS) and the order's effective tax rate (for the
        // tax refunded alongside the goods). Refunding the goods' tax keeps the
        // reversal balanced and the output-VAT liability correct.
        final costMap = await _costMap(session, orderId);
        var cogsTotal = Money.zero();
        for (final line in selected) {
          final unitCost = costMap[line.orderItemId] ?? Money.zero();
          cogsTotal = cogsTotal.add(unitCost.multiply(line.quantity));
        }
        cogsTotal = cogsTotal.rounded();

        final orderRow = await session.execute(
          Sql.named(
            'SELECT subtotal, discount_amount, tax_amount FROM pos_orders WHERE id = @id',
          ),
          parameters: {'id': orderId},
        );
        final om = orderRow.first.toColumnMap();
        final revenueBase = Money.parse(
          om['subtotal'],
        ).subtract(Money.parse(om['discount_amount']));
        final orderTax = Money.parse(om['tax_amount']);
        final taxPortion = revenueBase.isPositive
            ? netTotal.multiply(orderTax).divide(revenueBase).rounded()
            : Money.zero();
        // The customer is refunded the goods plus their tax.
        final total = netTotal.add(taxPortion).rounded();

        // Attribute the refund to the cashier's currently-open shift (if any) so
        // a cash refund is subtracted from the drawer it actually left when that
        // shift is closed and reconciled.
        int? shiftId;
        if (userId != null) {
          final shiftResult = await session.execute(
            Sql.named('''
              SELECT id FROM pos_shifts
              WHERE status = 'open' AND cashier_id = @cashier_id
              ORDER BY opened_at DESC
              LIMIT 1
            '''),
            parameters: {'cashier_id': userId},
          );
          if (shiftResult.isNotEmpty) {
            shiftId = _asInt(shiftResult.first.toColumnMap()['id']);
          }
        }

        final seq = await session.execute(
          "SELECT nextval('sales_return_seq')::bigint AS seq",
        );
        final returnNumber =
            'RET-${_asInt(seq.first.toColumnMap()['seq']).toString().padLeft(6, '0')}';

        final head = await session.execute(
          Sql.named('''
            INSERT INTO sales_returns
              (return_number, pos_order_id, shift_id, cashier_id, reason, refund_method, total_amount, status)
            VALUES (@number, @order_id, @shift_id, @cashier_id, @reason, @method, @total, 'completed')
            RETURNING id, created_at
          '''),
          parameters: {
            'number': returnNumber,
            'order_id': orderId,
            'shift_id': shiftId,
            'cashier_id': userId,
            'reason': reason,
            'method': refundMethod.wire,
            'total': total.toStorageString(),
          },
        );
        final headMap = head.first.toColumnMap();
        final returnId = _asInt(headMap['id']);

        for (final line in selected) {
          final unitCost = costMap[line.orderItemId] ?? Money.zero();
          await session.execute(
            Sql.named('''
              INSERT INTO sales_return_items
                (sales_return_id, pos_order_item_id, product_id, name, quantity, unit_price, line_total, unit_cost)
              VALUES (@return_id, @order_item_id, @product_id, @name, @quantity, @unit_price, @line_total, @unit_cost)
            '''),
            parameters: {
              'return_id': returnId,
              'order_item_id': line.orderItemId,
              'product_id': line.productId,
              'name': line.name,
              'quantity': line.quantity,
              'unit_price': line.unitPrice.toStorageString(),
              'line_total': line.lineTotal.toStorageString(),
              'unit_cost': unitCost.toStorageString(),
            },
          );

          if (line.productId != null) {
            // Restock the product, weighting the returned units back in at the
            // cost they were sold at so the product's average cost (and thus its
            // inventory value) stays in step with the Inventory GL debit below.
            await session.execute(
              Sql.named('''
                UPDATE products
                SET cost_price = CASE
                      WHEN quantity_on_hand + @qty <= 0 THEN cost_price
                      ELSE round(
                        (quantity_on_hand * cost_price + @qty * @unit_cost::numeric)
                          / (quantity_on_hand + @qty), 2)
                    END,
                    quantity_on_hand = quantity_on_hand + @qty
                WHERE id = @product_id
              '''),
              parameters: {
                'qty': line.quantity,
                'unit_cost': unitCost.toStorageString(),
                'product_id': line.productId,
              },
            );
            await session.execute(
              Sql.named('''
                INSERT INTO stock_movements
                  (product_id, type, quantity, reference_type, reference_id, created_by)
                VALUES (@product_id, 'sales_return', @qty, 'sales_return', @return_id, @created_by)
              '''),
              parameters: {
                'product_id': line.productId,
                'qty': line.quantity,
                'return_id': returnId,
                'created_by': userId,
              },
            );
          }
        }

        // Reverse the original sale's GL impact:
        //   Dr Sales Revenue (net)   Dr Tax Payable (tax)
        //                            Cr Cash / Accounts Receivable (refund)
        //   Dr Inventory (cost)      Cr COGS (cost)
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
              @ref, 'sales_return', @source_id, 'return_posting', @description,
              CURRENT_DATE, NOW(), 'posted'
            )
            RETURNING id
          '''),
          parameters: {
            'ref': reference,
            'source_id': returnId,
            'description': 'Sales return $returnNumber',
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

        // A cash refund leaves the drawer (Cr Cash); store credit raises a
        // receivable owed back to the customer (Cr Accounts Receivable).
        final refundCode = refundMethod == RefundMethod.cash ? '1100' : '1200';
        await postLine('4100', 'debit', netTotal); // reverse revenue
        await postLine('2200', 'debit', taxPortion); // reverse output VAT
        await postLine(refundCode, 'credit', total); // refund paid / owed
        await postLine('1300', 'debit', cogsTotal); // restore inventory
        await postLine('5100', 'credit', cogsTotal); // reverse COGS

        return SalesReturnSummary(
          id: returnId,
          returnNumber: returnNumber,
          posOrderId: orderId,
          refundMethod: refundMethod,
          totalAmount: total,
          createdAt: _asDate(headMap['created_at']),
        );
      });
    } on ReturnException {
      rethrow;
    } catch (error) {
      throw ReturnException('Could not process the return: $error');
    }
  }

  /// Returns the still-returnable quantity per `pos_order_items.id` for [orderId].
  Future<Map<int, int>> _availableMap(Session session, int orderId) async {
    final lines = await session.execute(
      Sql.named('''
        SELECT i.id AS order_item_id, i.quantity AS sold,
               COALESCE((
                 SELECT SUM(ri.quantity)
                 FROM sales_return_items ri
                 WHERE ri.pos_order_item_id = i.id
               ), 0)::int AS returned
        FROM pos_order_items i
        WHERE i.pos_order_id = @order_id
      '''),
      parameters: {'order_id': orderId},
    );
    final map = <int, int>{};
    for (final row in lines) {
      final m = row.toColumnMap();
      map[_asInt(m['order_item_id'])] =
          _asInt(m['sold']) - _asInt(m['returned']);
    }
    return map;
  }

  /// Maps each `pos_order_items.id` to the cost the line was sold at, falling
  /// back to the product's current cost for orders predating cost capture.
  Future<Map<int, Money>> _costMap(Session session, int orderId) async {
    final rows = await session.execute(
      Sql.named('''
        SELECT poi.id AS order_item_id,
               COALESCE(NULLIF(poi.unit_cost, 0), p.cost_price, 0) AS unit_cost
        FROM pos_order_items poi
        LEFT JOIN products p ON p.id = poi.product_id
        WHERE poi.pos_order_id = @order_id
      '''),
      parameters: {'order_id': orderId},
    );
    final map = <int, Money>{};
    for (final row in rows) {
      final m = row.toColumnMap();
      map[_asInt(m['order_item_id'])] = Money.parse(m['unit_cost']);
    }
    return map;
  }

  /// Resolves each GL [codes] entry to its account id, throwing loudly if any is
  /// missing so the return rolls back before a sequence number is drawn.
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
        throw ReturnException(
          'GL account "$code" is not configured; cannot process the return.',
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

  DateTime _asDate(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
