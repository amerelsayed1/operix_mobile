import '../domain/catalog_models.dart';

/// Manages the units-of-measure catalogue (Settings → Units).
abstract interface class UnitRepository {
  /// All units, default first.
  Future<List<Unit>> list();

  Future<Unit> create(UnitDraft draft);

  Future<Unit> update(int id, UnitDraft draft);

  Future<void> delete(int id);

  /// Makes [id] the single default unit.
  Future<void> setDefault(int id);
}
