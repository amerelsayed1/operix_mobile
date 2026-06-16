import 'package:flutter/material.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer_models.dart';

/// Create / edit customer form, shown as a centered dialog. Pops `true` when a
/// customer is saved.
class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({
    required this.repository,
    this.customer,
    super.key,
  });

  final CustomerRepository repository;
  final Customer? customer;

  bool get isEditing => customer != null;

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _phone = TextEditingController();

  CustomerStatus _status = CustomerStatus.active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer != null) {
      _name.text = customer.name;
      _code.text = customer.code;
      _phone.text = customer.phone ?? '';
      _status = customer.status;
    } else {
      _suggestCode();
    }
  }

  Future<void> _suggestCode() async {
    try {
      final code = await widget.repository.suggestCode();
      if (mounted && _code.text.isEmpty) _code.text = code;
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = CustomerDraft(
      code: _code.text,
      name: _name.text,
      phone: _phone.text,
      status: _status,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEditing) {
        await widget.repository.update(widget.customer!.id, draft);
      } else {
        await widget.repository.create(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.couldNotSaveCustomer('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _statusLabel(CustomerStatus status) => switch (status) {
    CustomerStatus.active => context.l10n.statusActive,
    CustomerStatus.inactive => context.l10n.statusInactive,
    CustomerStatus.blocked => context.l10n.statusBlocked,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.isEditing ? l10n.editCustomerTitle : l10n.newCustomer,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _name,
                  label: l10n.customerNameLabel,
                  hint: l10n.customerNameHint,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.nameRequired
                      : null,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        controller: _code,
                        label: l10n.customerCodeLabel,
                        hint: l10n.customerCodeHint,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.codeRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        controller: _phone,
                        label: l10n.phoneLabel,
                        hint: l10n.optional,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                _statusField(),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  _ErrorBox(message: _error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            widget.isEditing ? l10n.saveChanges : l10n.createCustomerAction,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }

  Widget _statusField() {
    return DropdownButtonFormField<CustomerStatus>(
      initialValue: _status,
      decoration: InputDecoration(
        labelText: context.l10n.statusLabel,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final s in CustomerStatus.values)
          DropdownMenuItem(value: s, child: Text(_statusLabel(s))),
      ],
      onChanged: (value) =>
          setState(() => _status = value ?? CustomerStatus.active),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OperixColors.danger.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OperixColors.danger.withAlpha(70)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: OperixColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: OperixColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
