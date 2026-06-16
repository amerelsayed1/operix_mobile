import '../domain/supplier_models.dart';
import '../domain/value_objects/money.dart';
import 'supplier_repository.dart';

/// In-memory supplier store used when PostgreSQL is not configured. Starts empty.
class DemoSupplierRepository implements SupplierRepository {
  final List<Supplier> _suppliers = [];
  int _seq = 1;

  @override
  Future<List<Supplier>> list({
    String search = '',
    bool includeInactive = true,
  }) async {
    final q = search.trim().toLowerCase();
    final filtered =
        _suppliers.where((s) {
          if (!includeInactive && !s.isActive) return false;
          if (q.isEmpty) return true;
          return s.companyName.toLowerCase().contains(q) ||
              s.code.toLowerCase().contains(q) ||
              (s.phone ?? '').toLowerCase().contains(q);
        }).toList()..sort(
          (a, b) => a.companyName.toLowerCase().compareTo(
            b.companyName.toLowerCase(),
          ),
        );
    return filtered;
  }

  @override
  Future<String> suggestCode() async =>
      'SUP-${(_suppliers.length + 1).toString().padLeft(4, '0')}';

  @override
  Future<Supplier> create(SupplierDraft draft) async {
    if (_suppliers.any(
      (s) => s.code.toLowerCase() == draft.code.trim().toLowerCase(),
    )) {
      throw DuplicateSupplierCodeException(draft.code.trim());
    }
    final supplier = _fromDraft(_seq++, draft, Money.zero());
    _suppliers.add(supplier);
    return supplier;
  }

  @override
  Future<Supplier> update(int id, SupplierDraft draft) async {
    final index = _suppliers.indexWhere((s) => s.id == id);
    if (index < 0) throw const SupplierException('Supplier not found.');
    if (_suppliers.any(
      (s) =>
          s.id != id && s.code.toLowerCase() == draft.code.trim().toLowerCase(),
    )) {
      throw DuplicateSupplierCodeException(draft.code.trim());
    }
    final supplier = _fromDraft(id, draft, _suppliers[index].balance);
    _suppliers[index] = supplier;
    return supplier;
  }

  @override
  Future<void> delete(int id) async {
    _suppliers.removeWhere((s) => s.id == id);
  }

  Supplier _fromDraft(int id, SupplierDraft d, Money balance) {
    return Supplier(
      id: id,
      code: d.code.trim(),
      companyName: d.companyName.trim(),
      phone: (d.phone == null || d.phone!.trim().isEmpty)
          ? null
          : d.phone!.trim(),
      balance: balance,
      status: d.status,
    );
  }
}
