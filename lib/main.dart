import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/app_session.dart';
import 'src/app/locale_controller.dart';
import 'src/app/operix_app.dart';
import 'src/config/database_config.dart';
import 'src/data/auth_repository.dart';
import 'src/data/business_repository.dart';
import 'src/data/demo_auth_repository.dart';
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
import 'src/data/postgres_operix_repository.dart';
import 'src/data/postgres_pos_repository.dart';
import 'src/data/postgres_product_repository.dart';
import 'src/data/product_repository.dart';

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
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<AppSession>(create: (_) => AppSession()),
      ],
      child: const OperixApp(),
    ),
  );
}
