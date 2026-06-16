// Throwaway integration smoke test for the POS data layer against the local
// PostgreSQL (docker compose). Run with: dart run tool/pos_smoke.dart
// It creates the first admin (if needed) and inserts its own test products,
// since the database ships with no seeded data.
// ignore_for_file: avoid_print
import 'package:operix_mobile/src/config/database_config.dart';
import 'package:operix_mobile/src/data/operix_database.dart';
import 'package:operix_mobile/src/data/pos_repository.dart';
import 'package:operix_mobile/src/data/postgres_auth_repository.dart';
import 'package:operix_mobile/src/data/postgres_pos_repository.dart';
import 'package:operix_mobile/src/domain/pos_models.dart';
import 'package:operix_mobile/src/domain/value_objects/money.dart';

Future<void> main() async {
  final db = OperixDatabase(DatabaseConfig.fromEnvironment());
  final auth = PostgresAuthRepository(db);
  final pos = PostgresPosRepository(db);

  print('> ensure admin account');
  if (!await auth.hasUsers()) {
    await auth.createFirstAdmin(
      username: 'admin',
      fullName: 'Admin',
      password: 'admin123',
    );
    print('  created admin/admin123');
  }
  final user = await auth.login('admin', 'admin123');
  print('  logged in as ${user.fullName} (${user.role}) id=${user.id}');

  print('> insert test products');
  final conn = await db.connection();
  await conn.execute('''
    INSERT INTO products (sku, name, category, quantity_on_hand, reorder_level, unit_price)
    VALUES
      ('SMOKE-1', 'Smoke Shirt', 'Test', 80, 10, 520),
      ('SMOKE-2', 'Smoke Socks', 'Test', 200, 20, 95),
      ('SMOKE-3', 'Smoke Low', 'Test', 3, 5, 40)
    ON CONFLICT (sku) DO UPDATE SET quantity_on_hand = EXCLUDED.quantity_on_hand
  ''');

  final products = await pos.loadProducts();
  print('  loaded ${products.length} products');
  final shirt = products.firstWhere((p) => p.sku == 'SMOKE-1');
  final socks = products.firstWhere((p) => p.sku == 'SMOKE-2');
  print(
    '  shirt stock before: ${shirt.quantityOnHand}, socks: ${socks.quantityOnHand}',
  );

  final shift = await pos.openShift(cashier: user, openingFloat: Money.of('500'));
  print('> opened shift ${shift.shiftNumber} (id=${shift.id})');

  final lines = [
    CartLine(product: shirt, quantity: 2),
    CartLine(product: socks, quantity: 3),
  ];
  final subtotal = sumMoney(lines.map((l) => l.lineTotal));
  final total = subtotal;
  final tendered = Money.of('2000');
  final receipt = await pos.checkout(
    CheckoutRequest(
      cashier: user,
      shift: shift,
      lines: lines,
      payments: [PosPayment(method: PaymentMethod.cash, amount: total)],
      subtotal: subtotal,
      discount: Money.zero(),
      tax: Money.zero(),
      total: total,
      paidAmount: tendered,
      changeAmount: tendered - total,
    ),
  );
  print(
    '> checkout OK: ${receipt.receiptNumber} total=$total change=${receipt.changeAmount} items=${receipt.itemCount}',
  );

  final after = await pos.loadProducts();
  final shirtAfter = after.firstWhere((p) => p.sku == 'SMOKE-1');
  final socksAfter = after.firstWhere((p) => p.sku == 'SMOKE-2');
  print(
    '  shirt stock after: ${shirtAfter.quantityOnHand} (expected ${shirt.quantityOnHand - 2})',
  );
  print(
    '  socks stock after: ${socksAfter.quantityOnHand} (expected ${socks.quantityOnHand - 3})',
  );

  final orders = await pos.recentOrders(shiftId: shift.id);
  print('> recent orders for shift: ${orders.length}');
  for (final o in orders) {
    print(
      '  ${o.receiptNumber}  total=${o.total}  items=${o.itemCount}  pay=${o.paymentSummary}',
    );
  }

  final closed = await pos.closeShift(
    shift: shift,
    countedCash: Money.of('2500'),
    notes: 'smoke test',
  );
  print(
    '> closed shift: expected=${closed.expectedCash} counted=${closed.countedCash} diff=${closed.cashDifference}',
  );

  // Oversell guard
  try {
    final tiny = after.firstWhere((p) => p.sku == 'SMOKE-3'); // stock 3
    await pos.checkout(
      CheckoutRequest(
        cashier: user,
        shift: shift,
        lines: [CartLine(product: tiny, quantity: 9999)],
        payments: [
          PosPayment(
            method: PaymentMethod.cash,
            amount: tiny.unitPrice.multiply(9999),
          ),
        ],
        subtotal: tiny.unitPrice.multiply(9999),
        discount: Money.zero(),
        tax: Money.zero(),
        total: tiny.unitPrice.multiply(9999),
        paidAmount: tiny.unitPrice.multiply(9999),
        changeAmount: Money.zero(),
      ),
    );
    print('! oversell guard FAILED (should have thrown)');
  } on InsufficientStockException catch (e) {
    print('> oversell guard OK: ${e.message}');
  }

  await db.close();
  print('DONE');
}
