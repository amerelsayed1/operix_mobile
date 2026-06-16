import '../domain/customer_models.dart';

class CustomerException implements Exception {
  const CustomerException(this.message);
  final String message;
  @override
  String toString() => 'CustomerException: $message';
}

/// Raised when a customer code collides with an existing customer.
class DuplicateCustomerCodeException extends CustomerException {
  const DuplicateCustomerCodeException(String code)
    : super('A customer with code "$code" already exists.');
}

abstract interface class CustomerRepository {
  Future<List<Customer>> list({
    String search = '',
    bool includeInactive = true,
  });

  /// A suggested next customer code, e.g. `CUST-0007`.
  Future<String> suggestCode();

  Future<Customer> create(CustomerDraft draft);

  Future<Customer> update(int id, CustomerDraft draft);

  Future<void> delete(int id);
}
