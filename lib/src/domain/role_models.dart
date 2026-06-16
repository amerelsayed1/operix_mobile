// Roles & permissions domain for the Settings area. Mirrors the Operix web
// "الأدوار والصلاحيات" experience: a role has a name, an optional description
// and a set of granted permission keys. Permissions are organised into a static
// catalog of groups → modules → actions so the matrix dialog can render them.
//
// A permission key is `"<moduleKey>.<actionKey>"` (e.g. `pos.enter`). The
// catalog is the single source of truth for which keys exist; repositories only
// persist the granted subset.

import 'package:flutter/widgets.dart';

/// A single toggleable action inside a module (view / create / edit / …).
class PermissionAction {
  const PermissionAction(this.key, this.en, this.ar);

  final String key;
  final String en;
  final String ar;

  String label(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? ar : en;
}

/// A module groups the actions that can be granted for one feature area.
class PermissionModule {
  const PermissionModule({
    required this.key,
    required this.en,
    required this.ar,
    required this.actions,
  });

  final String key;
  final String en;
  final String ar;
  final List<PermissionAction> actions;

  String label(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? ar : en;

  /// All permission keys this module exposes (`module.action`).
  Iterable<String> get permissionKeys => actions.map((a) => '$key.${a.key}');

  String permissionKey(PermissionAction action) => '$key.${action.key}';
}

/// A top-level category shown as a collapsible section in the matrix dialog.
class PermissionGroup {
  const PermissionGroup({
    required this.key,
    required this.en,
    required this.ar,
    required this.modules,
  });

  final String key;
  final String en;
  final String ar;
  final List<PermissionModule> modules;

  String label(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? ar : en;
}

// ---------------------------------------------------------------------------
// Action presets (re-used across modules so labels stay consistent).
// ---------------------------------------------------------------------------
const _view = PermissionAction('view', 'View', 'عرض');
const _create = PermissionAction('create', 'Create', 'إنشاء');
const _edit = PermissionAction('edit', 'Edit', 'تعديل');
const _delete = PermissionAction('delete', 'Delete', 'حذف');

/// The full permission tree rendered by the matrix dialog. Order matters: it is
/// the order shown to the user.
const List<PermissionGroup> kPermissionCatalog = [
  PermissionGroup(
    key: 'core',
    en: 'Core',
    ar: 'النواة',
    modules: [
      PermissionModule(
        key: 'dashboard',
        en: 'Dashboard',
        ar: 'لوحة التحكم',
        actions: [_view],
      ),
      PermissionModule(
        key: 'settings',
        en: 'Settings',
        ar: 'الإعدادات',
        actions: [_view, _edit],
      ),
      PermissionModule(
        key: 'company',
        en: 'Company profile',
        ar: 'ملف الشركة',
        actions: [_view, _edit],
      ),
      PermissionModule(
        key: 'roles',
        en: 'Roles & permissions',
        ar: 'الأدوار والصلاحيات',
        actions: [_view, _create, _edit, _delete],
      ),
      PermissionModule(
        key: 'employees',
        en: 'Employees',
        ar: 'الموظفون',
        actions: [_view, _create, _edit, _delete],
      ),
      PermissionModule(
        key: 'profile',
        en: 'Personal profile',
        ar: 'الملف الشخصي',
        actions: [_edit],
      ),
      PermissionModule(
        key: 'billing',
        en: 'Billing & subscription',
        ar: 'الفوترة والاشتراك',
        actions: [_view, PermissionAction('manage', 'Manage', 'إدارة')],
      ),
      PermissionModule(
        key: 'branches',
        en: 'Branches',
        ar: 'الفروع',
        actions: [_view, _create, _edit, _delete],
      ),
    ],
  ),
  PermissionGroup(
    key: 'pos',
    en: 'Point of sale & shifts',
    ar: 'نقطة البيع والورديات',
    modules: [
      PermissionModule(
        key: 'pos',
        en: 'Point of sale',
        ar: 'نقطة البيع',
        actions: [
          PermissionAction('enter', 'Enter POS', 'الدخول لنقطة البيع'),
          _create,
          _edit,
          _delete,
          PermissionAction('browse', 'Browse items', 'تصفح الاصناف'),
          PermissionAction('assign', 'Assign customers', 'تعيين العملاء'),
        ],
      ),
      PermissionModule(
        key: 'shifts',
        en: 'Cash shifts (open / close)',
        ar: 'الورديات النقدية (فتح / إغلاق)',
        actions: [
          _view,
          PermissionAction('open', 'Open shift', 'فتح الوردية'),
          PermissionAction('close', 'Close shift', 'إغلاق الوردية'),
          _delete,
          PermissionAction(
            'extraAccounts',
            'Extra closing accounts',
            'اختيار حسابات إضافية لإغلاق الوردية',
          ),
        ],
      ),
    ],
  ),
  PermissionGroup(
    key: 'sales',
    en: 'Sales',
    ar: 'المبيعات',
    modules: [
      PermissionModule(
        key: 'salesInvoices',
        en: 'Sales invoices',
        ar: 'فواتير المبيعات',
        actions: [
          _view,
          _create,
          _edit,
          _delete,
          PermissionAction('approve', 'Approve', 'اعتماد'),
          PermissionAction('return', 'Process return', 'معالجة المرتجع'),
          PermissionAction('export', 'Export', 'تصدير'),
          PermissionAction(
            'collectCredit',
            'Collect credit',
            'تحصيل مدفوعات الأجل',
          ),
          PermissionAction('collectPayment', 'Collect payment', 'تحصيل دفعة'),
        ],
      ),
      PermissionModule(
        key: 'crm',
        en: 'Customers (CRM)',
        ar: 'العملاء (CRM)',
        actions: [_view, _create, _edit, _delete],
      ),
    ],
  ),
];

/// Every permission key defined by the catalog (used for the Admin role / the
/// "select all" affordances).
List<String> get allPermissionKeys => [
  for (final group in kPermissionCatalog)
    for (final module in group.modules) ...module.permissionKeys,
];

/// A role as shown in the roles list.
class Role {
  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.memberCount,
    required this.permissions,
  });

  final int id;
  final String name;
  final String description;

  /// System roles (e.g. the tenant administrator) cannot be deleted.
  final bool isSystem;
  final int memberCount;

  /// Granted permission keys (`module.action`).
  final Set<String> permissions;

  int get grantedCount => permissions.length;
}

/// Input for creating / updating a role.
class RoleDraft {
  const RoleDraft({
    required this.name,
    required this.description,
    required this.permissions,
  });

  final String name;
  final String description;
  final Set<String> permissions;
}
