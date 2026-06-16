import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/app_session.dart';
import 'src/app/locale_controller.dart';
import 'src/app/operix_app.dart';
import 'src/config/database_config.dart';
import 'src/data/auth_repository.dart';
import 'src/data/business_repository.dart';
import 'src/data/category_repository.dart';
import 'src/data/customer_repository.dart';
import 'src/data/demo_auth_repository.dart';
import 'src/data/demo_category_repository.dart';
import 'src/data/demo_unit_repository.dart';
import 'src/data/postgres_category_repository.dart';
import 'src/data/postgres_unit_repository.dart';
import 'src/data/unit_repository.dart';
import 'src/data/demo_customer_repository.dart';
import 'src/data/demo_supplier_repository.dart';
import 'src/data/demo_user_admin_repository.dart';
import 'src/data/demo_role_repository.dart';
import 'src/data/demo_business_repository.dart';
import 'src/data/demo_operix_repository.dart';
import 'src/data/demo_pos_repository.dart';
import 'src/data/operix_database.dart';
import 'src/data/demo_product_repository.dart';
import 'src/data/license_repository.dart';
import 'src/data/local_license_repository.dart';
import 'src/data/operix_repository.dart';
import 'src/data/pos_repository.dart';
import 'src/data/postgres_auth_repository.dart';
import 'src/data/postgres_business_repository.dart';
import 'src/data/postgres_customer_repository.dart';
import 'src/data/postgres_supplier_repository.dart';
import 'src/data/postgres_user_admin_repository.dart';
import 'src/data/postgres_role_repository.dart';
import 'src/data/role_repository.dart';
import 'src/data/postgres_operix_repository.dart';
import 'src/data/postgres_pos_repository.dart';
import 'src/data/postgres_product_repository.dart';
import 'src/data/postgres_purchase_invoice_repository.dart';
import 'src/data/postgres_returns_repository.dart';
import 'src/data/postgres_sales_invoice_repository.dart';
import 'src/data/postgres_sales_report_repository.dart';
import 'src/data/postgres_stock_repository.dart';
import 'src/data/product_repository.dart';
import 'src/data/demo_returns_repository.dart';
import 'src/data/demo_sales_report_repository.dart';
import 'src/data/demo_stock_repository.dart';
import 'src/data/returns_repository.dart';
import 'src/data/demo_purchase_invoice_repository.dart';
import 'src/data/purchase_invoice_repository.dart';
import 'src/data/demo_sales_invoice_repository.dart';
import 'src/data/sales_invoice_repository.dart';
import 'src/data/sales_report_repository.dart';
import 'src/data/stock_repository.dart';
import 'src/data/supplier_repository.dart';
import 'src/data/user_admin_repository.dart';
import 'src/domain/pos_models.dart';

bool get _isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Launch maximized on desktop so the POS terminal fills the screen.
  if (_isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      title: 'Operix Desktop',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final databaseConfig = DatabaseConfig.fromEnvironment();
  final database = OperixDatabase(databaseConfig);
  final usesDatabase = databaseConfig.isConfigured;

  final localeController = await LocaleController.load();

  final OperixRepository dashboardRepository = PostgresOperixRepository(
    config: databaseConfig,
    fallback: DemoOperixRepository(),
  );
  final AuthRepository authRepository = usesDatabase
      ? PostgresAuthRepository(database)
      : DemoAuthRepository();
  final BusinessRepository businessRepository = usesDatabase
      ? PostgresBusinessRepository(database)
      : DemoBusinessRepository();
  final LicenseRepository licenseRepository = LocalLicenseRepository();
  final PosRepository posRepository = usesDatabase
      ? PostgresPosRepository(database)
      : DemoPosRepository();
  final ProductRepository productRepository = usesDatabase
      ? PostgresProductRepository(database)
      : DemoProductRepository();
  final SalesReportRepository salesReportRepository = usesDatabase
      ? PostgresSalesReportRepository(database)
      : DemoSalesReportRepository();
  final SalesInvoiceRepository salesInvoiceRepository = usesDatabase
      ? PostgresSalesInvoiceRepository(database)
      : DemoSalesInvoiceRepository();
  final PurchaseInvoiceRepository purchaseInvoiceRepository = usesDatabase
      ? PostgresPurchaseInvoiceRepository(database)
      : DemoPurchaseInvoiceRepository();
  final StockRepository stockRepository = usesDatabase
      ? PostgresStockRepository(database)
      : DemoStockRepository();
  final ReturnsRepository returnsRepository = usesDatabase
      ? PostgresReturnsRepository(database)
      : DemoReturnsRepository();
  final CustomerRepository customerRepository = usesDatabase
      ? PostgresCustomerRepository(database)
      : DemoCustomerRepository();
  final SupplierRepository supplierRepository = usesDatabase
      ? PostgresSupplierRepository(database)
      : DemoSupplierRepository();
  final UserAdminRepository userAdminRepository = usesDatabase
      ? PostgresUserAdminRepository(database)
      : DemoUserAdminRepository();
  final RoleRepository roleRepository = usesDatabase
      ? PostgresRoleRepository(database)
      : DemoRoleRepository();
  final CategoryRepository categoryRepository = usesDatabase
      ? PostgresCategoryRepository(database)
      : DemoCategoryRepository();
  final UnitRepository unitRepository = usesDatabase
      ? PostgresUnitRepository(database)
      : DemoUnitRepository();

  // Restore a previously signed-in user so the cashier isn't forced to log in
  // on every app launch. If the stored user no longer exists / the DB is
  // unreachable, we silently fall back to the login screen.
  final prefs = await SharedPreferences.getInstance();
  AppUser? restoredUser;
  Set<String> restoredPermissions = const {};
  final savedUserId = prefs.getInt(AppSession.userIdKey);
  if (savedUserId != null) {
    try {
      restoredUser = await authRepository.findUser(savedUserId);
      if (restoredUser != null) {
        restoredPermissions = await roleRepository.permissionsFor(
          restoredUser.role,
        );
      }
    } catch (_) {
      restoredUser = null;
      restoredPermissions = const {};
    }
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseConfig>.value(value: databaseConfig),
        Provider<OperixRepository>.value(value: dashboardRepository),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<BusinessRepository>.value(value: businessRepository),
        Provider<LicenseRepository>.value(value: licenseRepository),
        Provider<PosRepository>.value(value: posRepository),
        Provider<ProductRepository>.value(value: productRepository),
        Provider<SalesReportRepository>.value(value: salesReportRepository),
        Provider<SalesInvoiceRepository>.value(value: salesInvoiceRepository),
        Provider<PurchaseInvoiceRepository>.value(
          value: purchaseInvoiceRepository,
        ),
        Provider<StockRepository>.value(value: stockRepository),
        Provider<ReturnsRepository>.value(value: returnsRepository),
        Provider<CustomerRepository>.value(value: customerRepository),
        Provider<SupplierRepository>.value(value: supplierRepository),
        Provider<UserAdminRepository>.value(value: userAdminRepository),
        Provider<RoleRepository>.value(value: roleRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<UnitRepository>.value(value: unitRepository),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<AppSession>(
          create: (_) => AppSession(
            prefs: prefs,
            roleRepository: roleRepository,
            initialUser: restoredUser,
            initialPermissions: restoredPermissions,
          ),
        ),
      ],
      child: const OperixApp(),
    ),
  );
}
