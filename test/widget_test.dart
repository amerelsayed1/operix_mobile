import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:operix_mobile/src/app/app_session.dart';
import 'package:operix_mobile/src/app/locale_controller.dart';
import 'package:operix_mobile/src/app/operix_app.dart';
import 'package:operix_mobile/src/config/database_config.dart';
import 'package:operix_mobile/src/data/auth_repository.dart';
import 'package:operix_mobile/src/data/business_repository.dart';
import 'package:operix_mobile/src/data/customer_repository.dart';
import 'package:operix_mobile/src/data/demo_auth_repository.dart';
import 'package:operix_mobile/src/data/demo_business_repository.dart';
import 'package:operix_mobile/src/data/demo_customer_repository.dart';
import 'package:operix_mobile/src/data/demo_supplier_repository.dart';
import 'package:operix_mobile/src/data/demo_user_admin_repository.dart';
import 'package:operix_mobile/src/data/demo_role_repository.dart';
import 'package:operix_mobile/src/data/role_repository.dart';
import 'package:operix_mobile/src/data/category_repository.dart';
import 'package:operix_mobile/src/data/demo_category_repository.dart';
import 'package:operix_mobile/src/data/unit_repository.dart';
import 'package:operix_mobile/src/data/demo_unit_repository.dart';
import 'package:operix_mobile/src/data/demo_license_repository.dart';
import 'package:operix_mobile/src/data/demo_operix_repository.dart';
import 'package:operix_mobile/src/data/demo_pos_repository.dart';
import 'package:operix_mobile/src/data/demo_product_repository.dart';
import 'package:operix_mobile/src/data/demo_returns_repository.dart';
import 'package:operix_mobile/src/data/demo_purchase_invoice_repository.dart';
import 'package:operix_mobile/src/data/demo_sales_invoice_repository.dart';
import 'package:operix_mobile/src/data/demo_sales_report_repository.dart';
import 'package:operix_mobile/src/data/demo_stock_repository.dart';
import 'package:operix_mobile/src/data/license_repository.dart';
import 'package:operix_mobile/src/data/operix_repository.dart';
import 'package:operix_mobile/src/data/pos_repository.dart';
import 'package:operix_mobile/src/data/product_repository.dart';
import 'package:operix_mobile/src/data/returns_repository.dart';
import 'package:operix_mobile/src/data/purchase_invoice_repository.dart';
import 'package:operix_mobile/src/data/sales_invoice_repository.dart';
import 'package:operix_mobile/src/data/sales_report_repository.dart';
import 'package:operix_mobile/src/data/stock_repository.dart';
import 'package:operix_mobile/src/data/supplier_repository.dart';
import 'package:operix_mobile/src/data/user_admin_repository.dart';
import 'package:operix_mobile/src/domain/license_models.dart';
import 'package:operix_mobile/src/domain/pos_models.dart';
import 'package:operix_mobile/src/domain/value_objects/money.dart';
import 'package:operix_mobile/src/licensing/license_constants.dart';

final _testProduct = PosProduct(
  id: 1,
  sku: 'TST-1',
  name: 'Test Shirt',
  category: 'Apparel',
  unitPrice: Money.of('100'),
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
      Provider<SalesReportRepository>.value(value: DemoSalesReportRepository()),
      Provider<SalesInvoiceRepository>.value(
        value: DemoSalesInvoiceRepository(),
      ),
      Provider<PurchaseInvoiceRepository>.value(
        value: DemoPurchaseInvoiceRepository(),
      ),
      Provider<StockRepository>.value(value: DemoStockRepository()),
      Provider<ReturnsRepository>.value(value: DemoReturnsRepository()),
      Provider<CustomerRepository>.value(value: DemoCustomerRepository()),
      Provider<SupplierRepository>.value(value: DemoSupplierRepository()),
      Provider<UserAdminRepository>.value(value: DemoUserAdminRepository()),
      Provider<RoleRepository>.value(value: DemoRoleRepository()),
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

    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('POS'), findsNothing);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('dashboard quick actions open their target workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    expect(find.text('New sales invoice'), findsOneWidget);

    await tester.tap(find.text('New sales invoice'));
    await tester.pumpAndSettle();

    expect(
      find.text('Create an official invoice for wholesalers or businesses.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard purchase quick action opens purchase invoice form', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await tester.tap(find.text('Purchase invoice'));
    await tester.pumpAndSettle();

    expect(find.text('New purchase invoice'), findsOneWidget);
    expect(find.text('Invoice items'), findsOneWidget);
  });

  testWidgets('sidebar sections expand and collapse', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    expect(find.text('Sales invoices'), findsNothing);

    await tester.tap(find.text('Finance').first);
    await tester.pumpAndSettle();
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Sales invoices'), findsNothing);

    await tester.tap(find.text('Sales').first);
    await tester.pumpAndSettle();
    expect(find.text('Sales invoices'), findsOneWidget);

    await tester.tap(find.text('Finance').first);
    await tester.pumpAndSettle();
    expect(find.text('Sales invoices'), findsNothing);
  });

  testWidgets('accounting report rows respond to taps', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await _tapSidebarItem(tester, 'Accounting');
    await _tapSidebarItem(tester, 'Accounts');
    expect(find.text('Trial balance'), findsWidgets);

    await tester.tap(find.text('Trial balance').last);
    await tester.pump();

    expect(find.text('Trial balance is not available yet.'), findsOneWidget);
  });

  testWidgets('settings edits company identity and refreshes sidebar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await _tapSidebarItem(tester, 'Settings');

    // The redesigned settings shows the grouped nav + company card.
    expect(find.text('Company information'), findsWidgets);
    expect(find.text('Roles & permissions'), findsOneWidget);
    expect(find.text('Payment methods'), findsOneWidget);

    // The company form uses labels above each field, so the business name is
    // the first text field in the form.
    await tester.enterText(find.byType(TextFormField).first, 'New Style Shop');
    final saveButton = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('New Style Shop'), findsWidgets);
  });

  testWidgets('roles screen creates a role shown in the user form', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await _tapSidebarItem(tester, 'Settings');
    await tester.tap(find.text('Roles & permissions'));
    await tester.pumpAndSettle();

    // Seeded roles are listed.
    expect(find.text('Admin'), findsWidgets);

    // Create a new role through the permissions matrix dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Add role'));
    await tester.pumpAndSettle();
    expect(find.text('New role'), findsOneWidget);
    // The role-name field is the first text field in the dialog.
    await tester.enterText(find.byType(TextFormField).first, 'Supervisor');
    await tester.pump();
    final saveBtn = find.widgetWithText(FilledButton, 'Save permissions');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn, warnIfMissed: true);
    await tester.pumpAndSettle();
    // Dialog closed and the new role appears in the list.
    expect(find.text('New role'), findsNothing);
    expect(find.text('Supervisor'), findsWidgets);
  });

  testWidgets('completes a POS sale: open shift, add item, pay, receipt', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap(products: [_testProduct]));
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    // Open the POS module.
    await _tapSidebarItem(tester, 'Finance');
    await _tapSidebarItem(tester, 'Sales');
    await _tapSidebarItem(tester, 'POS');

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
    await _tapSidebarItem(tester, 'Inventory');
    await _tapSidebarItem(tester, 'Items');
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

  testWidgets('creates a customer from the Customers module', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    // Open Customers -> empty state.
    await _tapSidebarItem(tester, 'Customers');
    await _tapSidebarItem(tester, 'All customers');
    expect(find.text('No customers yet'), findsOneWidget);

    // Open the create form (use the empty-state button).
    await tester.tap(find.widgetWithText(FilledButton, 'New customer').first);
    await tester.pumpAndSettle();
    expect(find.text('New customer'), findsWidgets);

    // Fill the required fields (code is auto-suggested) and save.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Cairo Trading Co.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create customer'));
    await tester.pumpAndSettle();

    // Back on the list, the new customer appears.
    expect(find.text('Cairo Trading Co.'), findsOneWidget);
  });

  testWidgets('creates a supplier from the Suppliers module', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await _tapSidebarItem(tester, 'Suppliers');
    await _tapSidebarItem(tester, 'All suppliers');
    expect(find.text('No suppliers yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New supplier').first);
    await tester.pumpAndSettle();
    expect(find.text('New supplier'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company name'),
      'Nile Distributors',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create supplier'));
    await tester.pumpAndSettle();

    expect(find.text('Nile Distributors'), findsOneWidget);
  });

  testWidgets('creates a user from the Users module', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    await _tapSidebarItem(tester, 'Users');
    await _tapSidebarItem(tester, 'All users');
    expect(find.text('No additional users'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New user').first);
    await tester.pumpAndSettle();
    expect(find.text('New user'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Sara Hassan',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'sara',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create user'));
    await tester.pumpAndSettle();

    expect(find.text('Sara Hassan'), findsOneWidget);
  });

  testWidgets('create sales invoice: add a product and save persists it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    // Seed a product via the Inventory module — the invoice item picker reads
    // the same ProductRepository.
    await _tapSidebarItem(tester, 'Inventory');
    await _tapSidebarItem(tester, 'Items');
    await tester.tap(find.widgetWithText(FilledButton, 'New product').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name *'),
      'Office Chair',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Selling price *'),
      '250',
    );
    // Give it opening stock — the sales invoice picker only lists in-stock items.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Opening stock'),
      '5',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create product'));
    await tester.pumpAndSettle();
    expect(find.text('Office Chair'), findsOneWidget);

    // Open the new sales invoice screen from the dashboard quick action.
    await _tapSidebarItem(tester, 'Dashboard');
    await tester.tap(find.text('New sales invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice items'), findsOneWidget);
    expect(find.text('No items added yet'), findsOneWidget);

    // Add the product through the picker.
    await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Add items'), findsOneWidget);
    await tester.tap(find.text('Office Chair').last);
    await tester.pumpAndSettle();

    // The item is on the invoice and the empty-state message is gone.
    expect(find.text('No items added yet'), findsNothing);
    expect(find.text('Office Chair'), findsWidgets);

    // Save persists the invoice and returns to the invoices list (on failure
    // the screen stays on the create form with an error instead).
    await tester.tap(find.widgetWithText(FilledButton, 'Save').first);
    await tester.pumpAndSettle();
    expect(find.text('Invoice items'), findsNothing);
    expect(find.text('Sales invoices'), findsWidgets);
  });

  testWidgets('create purchase invoice: add a product and save persists it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pumpWidget(_bootstrap());
    await tester.pumpAndSettle();

    await _completeBusinessSetup(tester);
    await _completeSetup(tester);

    // Seed a product so the purchase item picker has something to add.
    await _tapSidebarItem(tester, 'Inventory');
    await _tapSidebarItem(tester, 'Items');
    await tester.tap(find.widgetWithText(FilledButton, 'New product').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name *'),
      'Cotton Roll',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Selling price *'),
      '90',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create product'));
    await tester.pumpAndSettle();
    expect(find.text('Cotton Roll'), findsOneWidget);

    // Open the new purchase invoice screen from the dashboard quick action.
    await _tapSidebarItem(tester, 'Dashboard');
    await tester.tap(find.text('Purchase invoice'));
    await tester.pumpAndSettle();
    expect(find.text('New purchase invoice'), findsOneWidget);
    expect(find.text('Invoice items'), findsOneWidget);

    // Add the product through the picker.
    await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Add items'), findsOneWidget);
    await tester.tap(find.text('Cotton Roll').last);
    await tester.pumpAndSettle();
    expect(find.text('Cotton Roll'), findsWidgets);

    // Save persists the purchase invoice and returns to the list.
    await tester.tap(find.widgetWithText(FilledButton, 'Save').first);
    await tester.pumpAndSettle();
    expect(find.text('New purchase invoice'), findsNothing);
    expect(find.text('Purchase invoices'), findsWidgets);
  });
}
