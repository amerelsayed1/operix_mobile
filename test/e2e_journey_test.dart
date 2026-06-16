// End-to-end journey test: drives the real OperixApp through the full first-run
// happy path and narrates every step to the console, so running it shows the
// flow start to finish.
//
//   flutter test test/e2e_journey_test.dart
//
// It is deterministic and needs no PostgreSQL — the app is wired with the
// in-memory demo repositories, exactly as the app falls back to when no database
// is configured.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:operix_mobile/src/app/app_session.dart';
import 'package:operix_mobile/src/app/locale_controller.dart';
import 'package:operix_mobile/src/app/operix_app.dart';
import 'package:operix_mobile/src/config/database_config.dart';
import 'package:operix_mobile/src/data/auth_repository.dart';
import 'package:operix_mobile/src/data/business_repository.dart';
import 'package:operix_mobile/src/data/demo_auth_repository.dart';
import 'package:operix_mobile/src/data/demo_business_repository.dart';
import 'package:operix_mobile/src/data/demo_operix_repository.dart';
import 'package:operix_mobile/src/data/demo_pos_repository.dart';
import 'package:operix_mobile/src/data/demo_product_repository.dart';
import 'package:operix_mobile/src/data/demo_returns_repository.dart';
import 'package:operix_mobile/src/data/demo_sales_report_repository.dart';
import 'package:operix_mobile/src/data/demo_stock_repository.dart';
import 'package:operix_mobile/src/data/category_repository.dart';
import 'package:operix_mobile/src/data/demo_category_repository.dart';
import 'package:operix_mobile/src/data/unit_repository.dart';
import 'package:operix_mobile/src/data/demo_unit_repository.dart';
import 'package:operix_mobile/src/data/license_repository.dart';
import 'package:operix_mobile/src/data/operix_repository.dart';
import 'package:operix_mobile/src/data/pos_repository.dart';
import 'package:operix_mobile/src/data/product_repository.dart';
import 'package:operix_mobile/src/data/returns_repository.dart';
import 'package:operix_mobile/src/data/sales_report_repository.dart';
import 'package:operix_mobile/src/data/stock_repository.dart';
import 'package:operix_mobile/src/domain/license_models.dart';
import 'package:operix_mobile/src/domain/pos_models.dart';
import 'package:operix_mobile/src/domain/value_objects/money.dart';
import 'package:operix_mobile/src/licensing/license_constants.dart';

/// A sellable product seeded into the POS so the sale step has something to ring.
final _shirt = PosProduct(
  id: 1,
  sku: 'TST-1',
  name: 'Test Shirt',
  category: 'Apparel',
  unitPrice: Money.of('100'),
  quantityOnHand: 10,
);

int _step = 0;
void step(String label) {
  _step++;
  print('\n──────── STEP $_step: $label ────────');
}

void note(String detail) => print('   • $detail');

Future<void> _tapSidebarItem(WidgetTester tester, String label) async {
  final item = find.text(label);
  final scrollable = find.byType(Scrollable).first;
  if (item.evaluate().isEmpty) {
    await tester.dragUntilVisible(
      item,
      scrollable,
      const Offset(0, -360),
      maxIteration: 20,
    );
  }
  await tester.ensureVisible(item.first);
  await tester.pumpAndSettle();
  await tester.tap(item.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('E2E journey: license → setup → admin → product → POS sale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap(products: [_shirt]));
    await tester.pumpAndSettle();

    // ── 1. License gate ────────────────────────────────────────────────────
    step('App launches behind the license gate');
    expect(find.text('License required'), findsOneWidget);
    expect(find.text('OPX-TEST-ACTIVATION'), findsOneWidget);
    note('License screen shown with this workstation\'s installation id');

    step('Activate the license');
    await tester.enterText(
      find.widgetWithText(TextField, 'License key'),
      'VALID-LICENSE',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Activate license'));
    await tester.pumpAndSettle();
    // Activation pops a "License accepted." snackbar via the app-level
    // ScaffoldMessenger. pumpAndSettle won't fire its 4s timer, so it would
    // otherwise linger at the bottom and cover controls (e.g. the POS charge
    // button) for the rest of the journey. Advance time to dismiss it cleanly.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    note('License accepted → business setup appears');

    // ── 2. Business identity ───────────────────────────────────────────────
    step('Set up the business identity');
    expect(find.text('Business identity'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Business name'),
      'Style Shop',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Branch name'),
      'Cairo branch',
    );
    final saveBusiness = find.widgetWithText(
      FilledButton,
      'Save business identity',
    );
    await tester.ensureVisible(saveBusiness);
    await tester.tap(saveBusiness);
    await tester.pumpAndSettle();
    note('Saved "Style Shop / Cairo branch"');

    // ── 3. Administrator account ───────────────────────────────────────────
    step('Create the administrator account');
    expect(find.text('Set up administrator'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Test Admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'admin123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'admin123',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Create account & continue'),
    );
    await tester.pumpAndSettle();
    note('Admin created and signed in → main shell');

    // ── 4. Reached the shell ───────────────────────────────────────────────
    step('Land in the main desktop shell');
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('POS'), findsNothing);
    expect(find.text('Dashboard'), findsWidgets);
    note('Sidebar shows top-level sections collapsed by default');

    // ── 5. Ring up a POS sale ──────────────────────────────────────────────
    step('Open a cashier shift in POS');
    await _tapSidebarItem(tester, 'Finance');
    await _tapSidebarItem(tester, 'Sales');
    await _tapSidebarItem(tester, 'POS');
    expect(find.text('Open a cashier shift'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Opening cash float'),
      '500',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Open shift'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Shift SH-'), findsOneWidget);
    note('Shift opened with EGP 500 float');

    step('Add an item to the cart');
    await tester.tap(find.text('Test Shirt'));
    await tester.pump();
    expect(find.text('Current sale'), findsOneWidget);
    note('"Test Shirt" (EGP 100) added to the cart');

    step('Take payment');
    await tester.tap(find.widgetWithText(FilledButton, 'Charge EGP 100.00'));
    await tester.pumpAndSettle();
    expect(find.text('Take payment'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm payment'));
    await tester.pumpAndSettle();
    note('Cash tender added and payment confirmed');

    step('Receipt prints, then the cart resets');
    expect(find.text('Sales Receipt'), findsOneWidget);
    expect(find.textContaining('POS-'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('Cart is empty'), findsOneWidget);
    note('Receipt shown (POS-…) and the cart cleared — sale complete');

    // ── 6. Create a product ────────────────────────────────────────────────
    step('Create a product in the Inventory module');
    await _tapSidebarItem(tester, 'Inventory');
    await _tapSidebarItem(tester, 'Items');
    expect(find.text('No products yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'New product').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name *'),
      'Coffee Mug',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Selling price *'),
      '50',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create product'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee Mug'), findsOneWidget);
    note('"Coffee Mug" @ EGP 50 created and listed');

    // ── 11. Sales reports ──────────────────────────────────────────────────
    step('Open the Sales Reports module');
    await _tapSidebarItem(tester, 'Reports');
    await _tapSidebarItem(tester, 'Shift reports');
    expect(find.text('Sales reports'), findsOneWidget);
    expect(find.text('REVENUE'), findsOneWidget);
    note('Reports screen renders with period metrics (revenue, profit, …)');

    print('\n✅ JOURNEY COMPLETE — all $_step steps passed.\n');
  });
}

// ── Test harness ───────────────────────────────────────────────────────────

/// Boots the real [OperixApp] with the in-memory demo repositories and a manual
/// license repository (so the license-activation step can be exercised).
Widget _bootstrap({List<PosProduct> products = const []}) {
  const config = DatabaseConfig(
    connectionUrl: '',
    host: '',
    port: 5433,
    database: '',
    username: '',
    password: '',
    sslModeName: 'disable',
  );
  return MultiProvider(
    providers: [
      Provider<DatabaseConfig>.value(value: config),
      Provider<OperixRepository>.value(value: DemoOperixRepository()),
      Provider<AuthRepository>.value(value: DemoAuthRepository()),
      Provider<BusinessRepository>.value(value: DemoBusinessRepository()),
      Provider<LicenseRepository>.value(value: _ManualLicenseRepository()),
      Provider<PosRepository>.value(
        value: DemoPosRepository(products: products),
      ),
      Provider<ProductRepository>.value(value: DemoProductRepository()),
      Provider<SalesReportRepository>.value(value: DemoSalesReportRepository()),
      Provider<StockRepository>.value(value: DemoStockRepository()),
      Provider<ReturnsRepository>.value(value: DemoReturnsRepository()),
      Provider<CategoryRepository>.value(value: DemoCategoryRepository()),
      Provider<UnitRepository>.value(value: DemoUnitRepository()),
      ChangeNotifierProvider<LocaleController>(
        create: (_) => LocaleController(),
      ),
      ChangeNotifierProvider<AppSession>(create: (_) => AppSession()),
    ],
    child: const OperixApp(),
  );
}

/// License repository that starts unactivated and accepts the key 'VALID-LICENSE'.
class _ManualLicenseRepository implements LicenseRepository {
  bool activated = false;

  @override
  Future<String> installationId() async => 'OPX-TEST-ACTIVATION';

  @override
  Future<LicenseValidationResult> loadLicense() async {
    if (activated) return _valid('License active.');
    return const LicenseValidationResult(
      status: LicenseStatus.missing,
      message: 'No Operix license is activated on this workstation.',
      installationId: 'OPX-TEST-ACTIVATION',
    );
  }

  @override
  Future<LicenseValidationResult> activate(String licenseKey) async {
    if (licenseKey.trim() != 'VALID-LICENSE') {
      return const LicenseValidationResult(
        status: LicenseStatus.invalid,
        message: 'License key is invalid.',
        installationId: 'OPX-TEST-ACTIVATION',
      );
    }
    activated = true;
    return _valid('License accepted.');
  }

  LicenseValidationResult _valid(String message) => LicenseValidationResult(
    status: LicenseStatus.valid,
    message: message,
    installationId: 'OPX-TEST-ACTIVATION',
    license: OperixLicense(
      licenseId: 'OPX-TEST',
      businessName: 'Test Business',
      installationId: 'OPX-TEST-ACTIVATION',
      product: kOperixLicenseProduct,
      plan: 'desktop-local',
      issuedAt: DateTime.utc(2026),
      validFrom: DateTime.utc(2026),
      expiresAt: DateTime.utc(2099, 12, 31),
      maxDevices: 1,
      modules: const ['pos', 'inventory'],
      token: 'VALID-LICENSE',
    ),
  );
}
