import 'package:postgres/postgres.dart';

import '../domain/stock_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'stock_repository.dart';

class PostgresStockRepository implements StockRepository {
  PostgresStockRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<StockMovement>> recentMovements({
    int? productId,
    int limit = 100,
  }) async {
    final conn = await database.connection();
    final filter = productId == null ? '' : 'WHERE sm.product_id = @product_id';
    final result = await conn.execute(
      Sql.named('''
        SELECT sm.id, sm.product_id,
               COALESCE(p.name, '(deleted product)') AS name,
               COALESCE(p.sku, '') AS sku,
               sm.type, sm.quantity, sm.reason, sm.note,
               sm.reference_type, sm.reference_id, sm.created_at
        FROM stock_movements sm
        LEFT JOIN products p ON p.id = sm.product_id
        $filter
        ORDER BY sm.created_at DESC, sm.id DESC
        LIMIT @limit
      '''),
      parameters: {'product_id': ?productId, 'limit': limit},
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return StockMovement(
        id: _asInt(m['id']),
        productId: m['product_id'] == null ? null : _asInt(m['product_id']),
        productName: m['name']?.toString() ?? '',
        sku: m['sku']?.toString() ?? '',
        type: StockMovementTypeX.fromWire(m['type']?.toString() ?? ''),
        quantity: _asInt(m['quantity']),
        reason: m['reason'] as String?,
        note: m['note'] as String?,
        referenceType: m['reference_type'] as String?,
        referenceId: m['reference_id'] == null
            ? null
            : _asInt(m['reference_id']),
        createdAt: _asDate(m['created_at']),
      );
    }).toList();
  }

  @override
  Future<void> adjust({
    required int productId,
    required int delta,
    required String reason,
    String? note,
    int? userId,
    Money? unitCost,
  }) async {
    if (delta == 0) {
      throw const StockException('Enter a non-zero adjustment quantity.');
    }
    final conn = await database.connection();
    try {
      await conn.runTx((session) async {
        // Read the current quantity and average cost up front so we can value the
        // movement and weight any new cost into the average.
        final prod = await session.execute(
          Sql.named(
            'SELECT quantity_on_hand, cost_price FROM products WHERE id = @id',
          ),
          parameters: {'id': productId},
        );
        if (prod.isEmpty) {
          throw const StockException('Product not found.');
        }
        final pm = prod.first.toColumnMap();
        final onHand = _asInt(pm['quantity_on_hand']);
        final currentCost = Money.parse(pm['cost_price']);

        // An increase carried at a supplied cost rolls the average cost forward
        // (weighted average, like a purchase); everything else keeps the current
        // cost. The GL value is always quantity × the cost being moved.
        final addingWithCost =
            delta > 0 && unitCost != null && unitCost.isPositive;
        final costUsed = addingWithCost ? unitCost : currentCost;
        final value = costUsed.multiply(delta.abs()).rounded();

        var newCost = currentCost;
        if (addingWithCost) {
          final totalQty = onHand + delta;
          newCost = totalQty <= 0
              ? unitCost
              : currentCost
                    .multiply(onHand)
                    .add(unitCost.multiply(delta))
                    .divide(totalQty)
                    .rounded();
        }

        final updated = await session.execute(
          Sql.named('''
            UPDATE products
            SET quantity_on_hand = quantity_on_hand + @delta,
                cost_price = @cost_price
            WHERE id = @id AND quantity_on_hand + @delta >= 0
          '''),
          parameters: {
            'delta': delta,
            'cost_price': newCost.toStorageString(),
            'id': productId,
          },
        );
        if (updated.affectedRows == 0) {
          // Either the product is missing or the result would be negative.
          throw const StockException('Adjustment would take stock below zero.');
        }

        final movement = await session.execute(
          Sql.named('''
            INSERT INTO stock_movements (product_id, type, quantity, reason, note, created_by)
            VALUES (@product_id, 'adjustment', @quantity, @reason, @note, @created_by)
            RETURNING id
          '''),
          parameters: {
            'product_id': productId,
            'quantity': delta,
            'reason': reason,
            'note': note,
            'created_by': userId,
          },
        );
        final movementId = _asInt(movement.first.toColumnMap()['id']);

        // Post the GL entry. Adding stock debits Inventory (1300) and credits the
        // Inventory Adjustment account (5300, a gain); removing stock does the
        // reverse (a loss). Skipped when the moved value is zero (e.g. an item
        // with no cost yet) — nothing of value changed hands.
        if (value.isPositive) {
          await _postAdjustment(
            session,
            sourceId: movementId,
            isIncrease: delta > 0,
            value: value,
            reason: reason,
          );
        }
      });
    } on StockException {
      rethrow;
    } catch (error) {
      throw StockException('Could not adjust stock: $error');
    }
  }

  /// Posts the balanced inventory-adjustment journal: Dr 1300 / Cr 5300 for an
  /// increase, the reverse for a decrease.
  Future<void> _postAdjustment(
    Session session, {
    required int sourceId,
    required bool isIncrease,
    required Money value,
    required String reason,
  }) async {
    final accountResult = await session.execute(
      Sql.named("SELECT code, id FROM gl_accounts WHERE code = ANY(@codes)"),
      parameters: {
        'codes': ['1300', '5300'],
      },
    );
    final accounts = <String, int>{};
    for (final row in accountResult) {
      final m = row.toColumnMap();
      accounts[m['code'] as String] = _asInt(m['id']);
    }
    for (final code in const ['1300', '5300']) {
      if (!accounts.containsKey(code)) {
        throw StockException(
          'GL account "$code" is not configured; cannot post the adjustment.',
        );
      }
    }

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
          @ref, 'stock_adjustment', @source_id, 'adjustment_posting', @description,
          CURRENT_DATE, NOW(), 'posted'
        )
        RETURNING id
      '''),
      parameters: {
        'ref': reference,
        'source_id': sourceId,
        'description': 'Stock adjustment ($reason)',
      },
    );
    final entryId = _asInt(entryResult.first.toColumnMap()['id']);

    Future<void> postLine(String code, String type) async {
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
          'amount': value.toStorageString(),
        },
      );
    }

    if (isIncrease) {
      await postLine('1300', 'debit'); // Inventory up
      await postLine('5300', 'credit'); // adjustment gain
    } else {
      await postLine('5300', 'debit'); // adjustment loss
      await postLine('1300', 'credit'); // Inventory down
    }
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
