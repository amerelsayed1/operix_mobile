import 'package:postgres/postgres.dart';

import '../domain/pos_models.dart';
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
    final result = await conn.execute('''
      SELECT id, sku, name, category, quantity_on_hand, unit_price
      FROM products
      WHERE is_active = TRUE
      ORDER BY category ASC, name ASC
    ''');
    return result.map((row) {
      final map = row.toColumnMap();
      return PosProduct(
        id: _asInt(map['id']),
        sku: _asString(map['sku']),
        name: _asString(map['name']),
        category: _asString(map['category']),
        unitPrice: _asDouble(map['unit_price']),
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
    required double openingFloat,
  }) async {
    final conn = await database.connection();
    final seq = await conn.execute(
      "SELECT nextval('pos_shift_seq')::bigint AS seq",
    );
    final shiftNumber =
        'SH-${_asInt(seq.first.toColumnMap()['seq']).toString().padLeft(4, '0')}';

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO pos_shifts (shift_number, cashier_id, cashier_name, opening_float, status)
        VALUES (@number, @cashier_id, @cashier_name, @opening_float, 'open')
        RETURNING id, opened_at
      '''),
      parameters: {
        'number': shiftNumber,
        'cashier_id': cashier.id,
        'cashier_name': cashier.fullName,
        'opening_float': openingFloat,
      },
    );
    final map = result.first.toColumnMap();
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
    required double countedCash,
    String? notes,
  }) async {
    final conn = await database.connection();
    final cashResult = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(p.amount), 0) AS cash
        FROM pos_order_payments p
        JOIN pos_orders o ON o.id = p.pos_order_id
        WHERE o.shift_id = @shift_id AND p.method = 'cash'
      '''),
      parameters: {'shift_id': shift.id},
    );
    final cashSales = _asDouble(cashResult.first.toColumnMap()['cash']);
    final expectedCash = shift.openingFloat + cashSales;
    final difference = countedCash - expectedCash;

    final result = await conn.execute(
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
        'expected': expectedCash,
        'counted': countedCash,
        'difference': difference,
        'notes': notes,
        'shift_id': shift.id,
      },
    );

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
            'subtotal': request.subtotal,
            'discount': request.discount,
            'tax': request.tax,
            'total': request.total,
            'paid': request.paidAmount,
            'change': request.changeAmount,
          },
        );
        final orderMap = orderResult.first.toColumnMap();
        final orderId = _asInt(orderMap['id']);
        final createdAt = _asDate(orderMap['created_at']);

        final receiptLines = <ReceiptLine>[];
        for (final line in request.lines) {
          await session.execute(
            Sql.named('''
              INSERT INTO pos_order_items (pos_order_id, product_id, name, quantity, unit_price)
              VALUES (@order_id, @product_id, @name, @quantity, @unit_price)
            '''),
            parameters: {
              'order_id': orderId,
              'product_id': line.product.id,
              'name': line.product.name,
              'quantity': line.quantity,
              'unit_price': line.product.unitPrice,
            },
          );

          final updated = await session.execute(
            Sql.named('''
              UPDATE products
              SET quantity_on_hand = quantity_on_hand - @quantity
              WHERE id = @product_id AND quantity_on_hand >= @quantity
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
              'amount': payment.amount,
              'reference': payment.reference,
            },
          );
        }

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
        total: _asDouble(map['total_amount']),
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
        unitPrice: _asDouble(map['unit_price']),
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
        amount: _asDouble(map['amount']),
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
      subtotal: _asDouble(head['subtotal']),
      discount: _asDouble(head['discount_amount']),
      tax: _asDouble(head['tax_amount']),
      total: _asDouble(head['total_amount']),
      paidAmount: _asDouble(head['paid_amount']),
      changeAmount: _asDouble(head['change_amount']),
      customerName: head['customer_name'] as String?,
    );
  }

  PosShift _shiftFromRow(Map<String, dynamic> map) {
    return PosShift(
      id: _asInt(map['id']),
      shiftNumber: _asString(map['shift_number']),
      cashierId: _asInt(map['cashier_id']),
      cashierName: _asString(map['cashier_name']),
      openingFloat: _asDouble(map['opening_float']),
      status: _asString(map['status']),
      openedAt: _asDate(map['opened_at']),
      closedAt: map['closed_at'] == null ? null : _asDate(map['closed_at']),
      notes: map['notes'] as String?,
    );
  }

  String _asString(Object? value) => value?.toString() ?? '';

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _asDate(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
