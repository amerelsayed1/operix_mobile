import '../domain/supplier_models.dart';

class SupplierException implements Exception {
  const SupplierException(this.message);
  final String message;
  @override
  String toString() => 'SupplierException: $message';
}

/// Raised when a supplier code collides with an existing supplier.
class DuplicateSupplierCodeException extends SupplierException {
  const DuplicateSupplierCodeException(String code)
    : super('A supplier with code "$code" already exists.');
}

abstract interface class SupplierRepository {
  Future<List<Supplier>> list({
    String search = '',
    bool includeInactive = true,
  });

  /// A suggested next supplier code, e.g. `SUP-0007`.
  Future<String> suggestCode();

  Future<Supplier> create(SupplierDraft draft);

  Future<Supplier> update(int id, SupplierDraft draft);

  Future<void> delete(int id);
}
