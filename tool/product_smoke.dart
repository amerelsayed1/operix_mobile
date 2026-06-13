// Throwaway check of PostgresProductRepository against the live DB.
// Run: dart run tool/product_smoke.dart
// ignore_for_file: avoid_print
import 'package:operix_mobile/src/config/database_config.dart';
import 'package:operix_mobile/src/data/operix_database.dart';
import 'package:operix_mobile/src/data/postgres_product_repository.dart';
import 'package:operix_mobile/src/data/product_repository.dart';
import 'package:operix_mobile/src/domain/inventory_models.dart';

Future<void> main() async {
  final db = OperixDatabase(DatabaseConfig.fromEnvironment());
  final repo = PostgresProductRepository(db);

  final sku = await repo.suggestSku();
  print('> suggested SKU: $sku');

  final created = await repo.create(
    ProductDraft(
      sku: sku,
      name: 'Wireless Keyboard',
      barcode: '6901234500001',
      category: 'Electronics',
      unit: 'Piece',
      costPrice: 150,
      sellingPrice: 220,
      minimumStockAlert: 10,
      quantityOnHand: 25,
      isActive: true,
    ),
  );
  print(
    '> created id=${created.id} ${created.sku} ${created.name} sell=${created.sellingPrice} stock=${created.quantityOnHand}',
  );

  try {
    await repo.create(
      ProductDraft(
        sku: sku,
        name: 'Dup',
        category: 'X',
        unit: 'Piece',
        costPrice: 0,
        sellingPrice: 1,
        minimumStockAlert: 0,
        quantityOnHand: 0,
        isActive: true,
      ),
    );
    print('! duplicate SKU guard FAILED');
  } on DuplicateSkuException catch (e) {
    print('> duplicate SKU guard OK: ${e.message}');
  }

  final updated = await repo.update(
    created.id,
    ProductDraft(
      sku: created.sku,
      name: 'Wireless Keyboard V2',
      category: 'Electronics',
      unit: 'Piece',
      costPrice: 150,
      sellingPrice: 240,
      minimumStockAlert: 5,
      quantityOnHand: 30,
      isActive: true,
    ),
  );
  print('> updated name=${updated.name} sell=${updated.sellingPrice}');

  final list = await repo.list(search: 'keyboard');
  print('> search "keyboard" -> ${list.length} result(s)');
  print('> categories: ${await repo.categories()}');

  await repo.delete(created.id);
  print(
    '> deleted; remaining matching: ${(await repo.list(search: 'keyboard')).length}',
  );

  await db.close();
  print('DONE');
}
