import 'package:postgres/postgres.dart';

import '../domain/report_models.dart';
import '../domain/value_objects/money.dart';
import 'operix_database.dart';
import 'sales_report_repository.dart';

class PostgresSalesReportRepository implements SalesReportRepository {
  PostgresSalesReportRepository(this.database);

  final OperixDatabase database;

  @override
  Future<SalesReport> generate({
    required DateTime from,
    required DateTime to,
  }) async {
    final conn = await database.connection();
    final params = {'from': from, 'to': to};

    // Revenue + transaction count (completed orders only).
    final summary = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(total_amount), 0) AS revenue,
               COUNT(*)::int AS txns
        FROM pos_orders
        WHERE status = 'completed'
          AND created_at >= @from AND created_at < @to
      '''),
      parameters: params,
    );
    final sumMap = summary.first.toColumnMap();

    // Estimated cost of goods sold (uses current product cost price).
    final cost = await conn.execute(
      Sql.named('''
        SELECT COALESCE(SUM(i.quantity * COALESCE(p.cost_price, 0)), 0) AS cost
        FROM pos_order_items i
        JOIN pos_orders o ON o.id = i.pos_order_id
        LEFT JOIN products p ON p.id = i.product_id
        WHERE o.status = 'completed'
          AND o.created_at >= @from AND o.created_at < @to
      '''),
      parameters: params,
    );

    // Top products by quantity sold.
    final top = await conn.execute(
      Sql.named('''
        SELECT i.name,
               COALESCE(p.sku, '') AS sku,
               SUM(i.quantity)::int AS qty,
               COALESCE(SUM(i.quantity * i.unit_price), 0) AS revenue
        FROM pos_order_items i
        JOIN pos_orders o ON o.id = i.pos_order_id
        LEFT JOIN products p ON p.id = i.product_id
        WHERE o.status = 'completed'
          AND o.created_at >= @from AND o.created_at < @to
        GROUP BY i.name, p.sku
        ORDER BY qty DESC, revenue DESC
        LIMIT 10
      '''),
      parameters: params,
    );

    // Breakdown by payment method.
    final pay = await conn.execute(
      Sql.named('''
        SELECT pay.method,
               COALESCE(SUM(pay.amount), 0) AS amount,
               COUNT(*)::int AS cnt
        FROM pos_order_payments pay
        JOIN pos_orders o ON o.id = pay.pos_order_id
        WHERE o.status = 'completed'
          AND o.created_at >= @from AND o.created_at < @to
        GROUP BY pay.method
        ORDER BY amount DESC
      '''),
      parameters: params,
    );

    return SalesReport(
      from: from,
      to: to,
      totalRevenue: Money.parse(sumMap['revenue']),
      transactionCount: _asInt(sumMap['txns']),
      estimatedCost: Money.parse(cost.first.toColumnMap()['cost']),
      topProducts: top.map((row) {
        final m = row.toColumnMap();
        return TopProduct(
          name: m['name']?.toString() ?? '',
          sku: m['sku']?.toString() ?? '',
          quantity: _asInt(m['qty']),
          revenue: Money.parse(m['revenue']),
        );
      }).toList(),
      paymentBreakdown: pay.map((row) {
        final m = row.toColumnMap();
        return PaymentBreakdown(
          method: m['method']?.toString() ?? '',
          amount: Money.parse(m['amount']),
          count: _asInt(m['cnt']),
        );
      }).toList(),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
