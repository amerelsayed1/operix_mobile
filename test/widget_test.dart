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
import 'package:operix_mobile/src/data/demo_license_repository.dart';
import 'package:operix_mobile/src/data/demo_operix_repository.dart';
import 'package:operix_mobile/src/data/demo_pos_repository.dart';
import 'package:operix_mobile/src/data/demo_product_repository.dart';
import 'package:operix_mobile/src/data/license_repository.dart';
import 'package:operix_mobile/src/data/operix_repository.dart';
import 'package:operix_mobile/src/data/pos_repository.dart';
import 'package:operix_mobile/src/data/product_repository.dart';
import 'package:operix_mobile/src/domain/license_models.dart';
import 'package:operix_mobile/src/domain/pos_models.dart';
import 'package:operix_mobile/src/licensing/license_constants.dart';

const _testProduct = PosProduct(
  id: 1,
  sku: 'TST-1',
  name: 'Test Shirt',
  category: 'Apparel',
  unitPrice: 100,
  quantityOnHand: 10,
);

class _ManualLicenseRepository implements LicenseRepository {
  bool activated = false;

  @override
  Future<String> installationId() async => 'OPX-TEST-ACTIVATION';

  @override
  Future<LicenseValidationResult> loadLicense() async {
    if (activated) {
      return _valid('License active.');
    }
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

  LicenseValidationResult _valid(String message) {
    return LicenseValidationResult(
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
}

Widget _bootstrap({
  List<PosProduct> products = const [],
  LicenseRepository? licenseRepository,
}) {
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
      Provider<LicenseRepository>.value(
        value: licenseRepository ?? DemoLicenseRepository(),
      ),
      Provider<PosRepository>.value(
        value: DemoPosRepository(products: products),
      ),
      Provider<ProductRepository>.value(value: DemoProductRepository()),
      ChangeNotifierProvider<LocaleController>(
        create: (_) => LocaleController(),
      ),
      ChangeNotifierProvider<AppSession>(create: (_) => AppSession()),
    ],
    child: const OperixApp(),
  );
}

Future<void> _completeBusinessSetup(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Business name'),
    'Style Shop',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Branch name'),
    'Cairo branch',
  );
  final saveButton = find.widgetWithText(
    FilledButton,
    'Save business identity',
  );
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

Future<void> _completeSetup(WidgetTester tester) async {
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
}

void main() {
  testWidgets('license activation unlocks the first-run setup', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _bootstrap(licenseRepository: _ManualLicenseRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('License required'), findsOneWidget);
    expect(find.text('OPX-TEST-ACTIVATION'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'License key'),
      'VALID-LICENSE',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Activate license'));
    await tester.pumpAndSettle();

    expect(find.text('Business identity'), findsOneWidget);
    expect(find.text('Test Business'), findsOneWidget);
    await _completeBusinessSetup(tester);

    expect(find.text('Set up administrator'), findsOneWidget);
  });

  testWidgets('first run shows the business setup screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Operix logo'), findsOneWidget);
    expect(find.text('Business identity'), findsOneWidget);
    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Business logo path'), findsOneWidget);
  });

  testWidgets('saving business identity opens administrator setup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);

    expect(find.text('Set up administrator'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('creating the admin reaches the shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    expect(find.text('POS'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('settings edits company identity and refreshes sidebar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();

    expect(find.text('Company information'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Business name'),
      'New Style Shop',
    );
    final saveButton = find.widgetWithText(
      FilledButton,
      'Save company settings',
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('New Style Shop'), findsWidgets);
  });

  testWidgets('completes a POS sale: open shift, add item, pay, receipt', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap(products: const [_testProduct]));
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    // Open the POS module.
    await tester.tap(find.text('POS').first);
    await tester.pumpAndSettle();

    // No open shift yet -> open-shift prompt.
    expect(find.text('Open a cashier shift'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Opening cash float'),
      '500',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Open shift'));
    await tester.pumpAndSettle();

    // Terminal is live; add the product to the cart.
    expect(find.textContaining('Shift SH-'), findsOneWidget);
    await tester.tap(find.text('Test Shirt'));
    await tester.pump();
    expect(find.text('Current sale'), findsOneWidget);

    // Charge -> payment dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Charge EGP 100.00'));
    await tester.pumpAndSettle();
    expect(find.text('Take payment'), findsOneWidget);

    // Add the (pre-filled) cash tender and confirm.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm payment'));
    await tester.pumpAndSettle();

    // Receipt preview appears.
    expect(find.text('Sales Receipt'), findsOneWidget);
    expect(find.textContaining('POS-'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();

    // Cart resets after the sale.
    expect(find.text('Cart is empty'), findsOneWidget);
  });

  testWidgets('creates a product from the Inventory module', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    // Open Inventory -> empty state.
    await tester.tap(find.text('Inventory').first);
    await tester.pumpAndSettle();
    expect(find.text('No products yet'), findsOneWidget);

    // Open the create form (use the empty-state button).
    await tester.tap(find.widgetWithText(FilledButton, 'New product').first);
    await tester.pumpAndSettle();
    expect(find.text('New product'), findsWidgets);

    // Fill the required fields (SKU is auto-suggested) and save.
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

    // Back on the list, the new product appears.
    expect(find.text('Coffee Mug'), findsOneWidget);
  });
}
