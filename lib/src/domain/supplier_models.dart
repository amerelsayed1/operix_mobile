// Supplier domain models for the Suppliers module: the searchable list and the
// create/edit form. Mirrors the local `suppliers` table (001 schema):
// id, supplier_code, company_name, phone, payable_balance, status, created_at.
//
// The payable balance is derived from purchase invoices/payments, so it is shown
// read-only here and never written by this form — only the descriptive fields
// (code, company name, phone, status) are editable.

import 'value_objects/money.dart';

/// Supplier account statuses (mirrors the customer status set).
enum SupplierStatus { active, inactive, blocked }

extension SupplierStatusX on SupplierStatus {
  String get wireValue => name; // active | inactive | blocked

  String get label {
    switch (this) {
      case SupplierStatus.active:
        return 'Active';
      case SupplierStatus.inactive:
        return 'Inactive';
      case SupplierStatus.blocked:
        return 'Blocked';
    }
  }

  static SupplierStatus fromWire(String? value) {
    return SupplierStatus.values.firstWhere(
      (s) => s.name == (value ?? '').trim().toLowerCase(),
      orElse: () => SupplierStatus.active,
    );
  }
}

/// A fully persisted supplier.
class Supplier {
  const Supplier({
    required this.id,
    required this.code,
    required this.companyName,
    required this.balance,
    required this.status,
    this.phone,
    this.createdAt,
  });

  final int id;
  final String code;
  final String companyName;
  final String? phone;
  final Money balance;
  final SupplierStatus status;
  final DateTime? createdAt;

  bool get isActive => status == SupplierStatus.active;

  /// True when money is owed to this supplier (positive payable).
  bool get isOwed => balance.isPositive;
}

/// Input for creating or updating a supplier. The payable balance is managed by
/// purchase flows, not edited directly.
class SupplierDraft {
  const SupplierDraft({
    required this.code,
    required this.companyName,
    required this.status,
    this.phone,
  });

  final String code;
  final String companyName;
  final String? phone;
  final SupplierStatus status;
}
