import '../domain/customer_models.dart';
import '../domain/value_objects/money.dart';
import 'customer_repository.dart';

/// In-memory customer store used when PostgreSQL is not configured. Starts empty.
class DemoCustomerRepository implements CustomerRepository {
  final List<Customer> _customers = [];
  int _seq = 1;

  @override
  Future<List<Customer>> list({
    String search = '',
    bool includeInactive = true,
  }) async {
    final q = search.trim().toLowerCase();
    final filtered =
        _customers.where((c) {
          if (!includeInactive && !c.isActive) return false;
          if (q.isEmpty) return true;
          return c.name.toLowerCase().contains(q) ||
              c.code.toLowerCase().contains(q) ||
              (c.phone ?? '').toLowerCase().contains(q);
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return filtered;
  }

  @override
  Future<String> suggestCode() async =>
      'CUST-${(_customers.length + 1).toString().padLeft(4, '0')}';

  @override
  Future<Customer> create(CustomerDraft draft) async {
    if (_customers.any(
      (c) => c.code.toLowerCase() == draft.code.trim().toLowerCase(),
    )) {
      throw DuplicateCustomerCodeException(draft.code.trim());
    }
    final customer = _fromDraft(_seq++, draft, Money.zero());
    _customers.add(customer);
    return customer;
  }

  @override
  Future<Customer> update(int id, CustomerDraft draft) async {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index < 0) throw const CustomerException('Customer not found.');
    if (_customers.any(
      (c) =>
          c.id != id && c.code.toLowerCase() == draft.code.trim().toLowerCase(),
    )) {
      throw DuplicateCustomerCodeException(draft.code.trim());
    }
    // Preserve the existing receivable balance across edits.
    final customer = _fromDraft(id, draft, _customers[index].balance);
    _customers[index] = customer;
    return customer;
  }

  @override
  Future<void> delete(int id) async {
    _customers.removeWhere((c) => c.id == id);
  }

  Customer _fromDraft(int id, CustomerDraft d, Money balance) {
    return Customer(
      id: id,
      code: d.code.trim(),
      name: d.name.trim(),
      phone: (d.phone == null || d.phone!.trim().isEmpty)
          ? null
          : d.phone!.trim(),
      balance: balance,
      status: d.status,
    );
  }
}
