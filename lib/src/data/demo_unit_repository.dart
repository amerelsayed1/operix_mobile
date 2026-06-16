import '../domain/catalog_models.dart';
import 'unit_repository.dart';

/// In-memory unit catalogue used when PostgreSQL is not configured. Seeded with
/// the same starter units as the database migration.
class DemoUnitRepository implements UnitRepository {
  DemoUnitRepository() {
    const seed = [
      ('Piece', 'قطعة', 'pcs', false, true),
      ('Box', 'صندوق', 'box', false, false),
      ('Kg', 'كيلو', 'kg', true, false),
      ('Liter', 'لتر', 'L', true, false),
    ];
    for (final (en, ar, code, dec, def) in seed) {
      _items.add(
        Unit(
          id: _seq++,
          nameEn: en,
          nameAr: ar,
          shortCode: code,
          allowDecimal: dec,
          isDefault: def,
        ),
      );
    }
  }

  final List<Unit> _items = [];
  int _seq = 1;

  @override
  Future<List<Unit>> list() async {
    final rows = [..._items]
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.canonicalName.compareTo(b.canonicalName);
      });
    return rows;
  }

  @override
  Future<Unit> create(UnitDraft draft) async {
    final (en, ar) = _normalize(draft);
    final unit = Unit(
      id: _seq++,
      nameEn: en,
      nameAr: ar,
      shortCode: draft.shortCode?.trim().isEmpty ?? true
          ? null
          : draft.shortCode!.trim(),
      description: draft.description?.trim().isEmpty ?? true
          ? null
          : draft.description!.trim(),
      allowDecimal: draft.allowDecimal,
      isDefault: _items.isEmpty,
    );
    _items.add(unit);
    return unit;
  }

  @override
  Future<Unit> update(int id, UnitDraft draft) async {
    final (en, ar) = _normalize(draft);
    final index = _items.indexWhere((u) => u.id == id);
    if (index < 0) throw const UnitException('Unit not found.');
    final old = _items[index];
    final updated = Unit(
      id: id,
      nameEn: en,
      nameAr: ar,
      shortCode: draft.shortCode?.trim().isEmpty ?? true
          ? null
          : draft.shortCode!.trim(),
      description: draft.description?.trim().isEmpty ?? true
          ? null
          : draft.description!.trim(),
      allowDecimal: draft.allowDecimal,
      isDefault: old.isDefault,
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    final removed = _items.indexWhere((u) => u.id == id);
    if (removed < 0) return;
    final wasDefault = _items[removed].isDefault;
    _items.removeAt(removed);
    if (wasDefault && _items.isNotEmpty) {
      final first = _items.first;
      _items[0] = Unit(
        id: first.id,
        nameEn: first.nameEn,
        nameAr: first.nameAr,
        shortCode: first.shortCode,
        description: first.description,
        allowDecimal: first.allowDecimal,
        isDefault: true,
      );
    }
  }

  @override
  Future<void> setDefault(int id) async {
    for (var i = 0; i < _items.length; i++) {
      final u = _items[i];
      _items[i] = Unit(
        id: u.id,
        nameEn: u.nameEn,
        nameAr: u.nameAr,
        shortCode: u.shortCode,
        description: u.description,
        allowDecimal: u.allowDecimal,
        isDefault: u.id == id,
      );
    }
  }

  (String, String) _normalize(UnitDraft draft) {
    final en = draft.nameEn.trim();
    final ar = draft.nameAr.trim();
    if (en.isEmpty && ar.isEmpty) {
      throw const UnitException('Enter a unit name.');
    }
    return (en.isNotEmpty ? en : ar, ar.isNotEmpty ? ar : en);
  }
}
