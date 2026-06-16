// Customer (client) domain models for the Customers module: the searchable list
// and the create/edit form. Mirrors the local `clients` table (001 schema):
// id, client_code, name, phone, receivable_balance, status, created_at.
//
// The receivable balance is derived from invoices/payments over the customer's
// lifetime, so it is shown read-only here and never written by this form — only
// the descriptive fields (code, name, phone, status) are editable.

import 'value_objects/money.dart';

/// Customer account statuses (mirrors the web client status set).
enum CustomerStatus { active, inactive, blocked }

extension CustomerStatusX on CustomerStatus {
  /// Value stored in the `status` column.
  String get wireValue => name; // active | inactive | blocked

  String get label {
    switch (this) {
      case CustomerStatus.active:
        return 'Active';
      case CustomerStatus.inactive:
        return 'Inactive';
      case CustomerStatus.blocked:
        return 'Blocked';
    }
  }

  static CustomerStatus fromWire(String? value) {
    return CustomerStatus.values.firstWhere(
      (s) => s.name == (value ?? '').trim().toLowerCase(),
      orElse: () => CustomerStatus.active,
    );
  }
}

/// A fully persisted customer.
class Customer {
  const Customer({
    required this.id,
    required this.code,
    required this.name,
    required this.balance,
    required this.status,
    this.phone,
    this.createdAt,
  });

  final int id;
  final String code;
  final String name;
  final String? phone;
  final Money balance;
  final CustomerStatus status;
  final DateTime? createdAt;

  bool get isActive => status == CustomerStatus.active;

  /// True when the customer owes money (positive receivable).
  bool get owesMoney => balance.isPositive;
}

/// Input for creating or updating a customer. The receivable balance is not part
/// of the draft — it is managed by sales/payment flows, not edited directly.
class CustomerDraft {
  const CustomerDraft({
    required this.code,
    required this.name,
    required this.status,
    this.phone,
  });

  final String code;
  final String name;
  final String? phone;
  final CustomerStatus status;
}
