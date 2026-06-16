import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/category_repository.dart';
import '../../data/product_repository.dart';
import '../../data/unit_repository.dart';
import '../../domain/catalog_models.dart';
import '../../domain/inventory_models.dart';
import '../../domain/value_objects/money.dart';

/// Create / edit product form, mirroring the Operix web `/products/create`
/// fields. Pushed as a full-screen route; pops `true` when a product is saved.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({required this.repository, this.product, super.key});

  final ProductRepository repository;
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _category = TextEditingController();
  final _costPrice = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _minStock = TextEditingController();
  final _stock = TextEditingController();

  String _unit = 'Piece';
  bool _isActive = true;
  bool _saving = false;
  String? _error;
  List<ProductCategory> _categoryList = [];
  List<Unit> _unitList = [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _sku.text = product.sku;
      _barcode.text = product.barcode ?? '';
      _category.text = product.category;
      _costPrice.text = _money(product.costPrice);
      _sellingPrice.text = _money(product.sellingPrice);
      _minStock.text = product.minimumStockAlert.toString();
      _stock.text = product.quantityOnHand.toString();
      _unit = product.unit.isEmpty ? 'Piece' : product.unit;
      _isActive = product.isActive;
    } else {
      _costPrice.text = '0';
      _minStock.text = '0';
      _stock.text = '0';
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Source categories and units from the managed catalogues (Settings → Item
    // categories / Units) rather than free text and a hardcoded list. The locale
    // is resolved later in build() — Localizations can't be read from initState.
    final categoryRepo = context.read<CategoryRepository>();
    final unitRepo = context.read<UnitRepository>();
    try {
      final cats = await categoryRepo.list();
      if (mounted) setState(() => _categoryList = cats);
    } catch (_) {}
    try {
      final units = await unitRepo.list();
      if (mounted) {
        setState(() {
          _unitList = units;
          // A new product defaults to the configured default unit (stored as its
          // locale-free canonical name, which is also the dropdown item value).
          if (!widget.isEditing) {
            final def = units.where((u) => u.isDefault);
            if (def.isNotEmpty) _unit = def.first.canonicalName;
          }
        });
      }
    } catch (_) {}
    if (!widget.isEditing) {
      try {
        final sku = await widget.repository.suggestSku();
        if (mounted && _sku.text.isEmpty) _sku.text = sku;
      } catch (_) {}
    }
  }

  String _money(Money v) {
    final s = v.toStorageString();
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _sku,
      _barcode,
      _category,
      _costPrice,
      _sellingPrice,
      _minStock,
      _stock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = ProductDraft(
      sku: _sku.text,
      name: _name.text,
      barcode: _barcode.text,
      category: _category.text,
      unit: _unit,
      costPrice: Money.fromNum(double.tryParse(_costPrice.text.trim()) ?? 0),
      sellingPrice: Money.fromNum(
        double.tryParse(_sellingPrice.text.trim()) ?? 0,
      ),
      minimumStockAlert: int.tryParse(_minStock.text.trim()) ?? 0,
      quantityOnHand: int.tryParse(_stock.text.trim()) ?? 0,
      isActive: _isActive,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEditing) {
        await widget.repository.update(widget.product!.id, draft);
      } else {
        await widget.repository.create(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.couldNotSaveProduct('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    // Dropdown items: value = locale-free canonical name (what we persist),
    // label = localized display name. Always include the current value so the
    // field never holds a value absent from its items.
    final unitOptions = <String, String>{};
    if (_unitList.isEmpty) {
      for (final u in kProductUnits) {
        unitOptions[u] = u;
      }
    } else {
      for (final u in _unitList) {
        unitOptions[u.canonicalName] = u.displayName(arabic);
      }
    }
    if (_unit.isNotEmpty) unitOptions.putIfAbsent(_unit, () => _unit);
    return Scaffold(
      backgroundColor: OperixColors.background,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editProductTitle : l10n.newProductTitle,
        ),
        backgroundColor: Colors.white,
        foregroundColor: OperixColors.ink,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: OperixColors.border)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: l10n.sectionProductDetails,
                    children: [
                      _field(
                        controller: _name,
                        label: l10n.productNameLabel,
                        hint: l10n.productNameHint,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.nameRequired
                            : null,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              controller: _sku,
                              label: l10n.skuLabel,
                              hint: l10n.skuHint,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.skuRequired
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              controller: _barcode,
                              label: l10n.barcodeLabel,
                              hint: l10n.optional,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _categoryField(arabic)),
                          const SizedBox(width: 16),
                          Expanded(child: _unitField(unitOptions)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.sectionPricing,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numberField(
                              controller: _costPrice,
                              label: l10n.costPriceLabel,
                              prefix: 'EGP ',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _numberField(
                              controller: _sellingPrice,
                              label: l10n.sellingPriceLabel,
                              prefix: 'EGP ',
                              validator: (v) {
                                final value = double.tryParse((v ?? '').trim());
                                if (value == null) return l10n.enterValidPrice;
                                if (value < 0) return l10n.cannotBeNegative;
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.sectionInventory,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numberField(
                              controller: _stock,
                              label: widget.isEditing
                                  ? l10n.stockOnHand
                                  : l10n.openingStock,
                              integer: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _numberField(
                              controller: _minStock,
                              label: l10n.minimumStockAlert,
                              integer: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.activeLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(l10n.activeSubtitle),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBox(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
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
                          widget.isEditing
                              ? l10n.saveChanges
                              : l10n.createProductAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    bool integer = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
          ),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }

  Widget _categoryField(bool arabic) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _category,
        decoration: InputDecoration(
          labelText: l10n.categoryLabel,
          hintText: l10n.categoryHint,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: _categoryList.isEmpty
              ? null
              : PopupMenuButton<String>(
                  tooltip: l10n.pickExisting,
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) => _category.text = value,
                  itemBuilder: (context) => [
                    for (final c in _categoryList)
                      PopupMenuItem(
                        value: c.canonicalName,
                        child: Text(c.displayName(arabic)),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _unitField(Map<String, String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('unit-$_unit'),
        initialValue: _unit,
        decoration: InputDecoration(
          labelText: context.l10n.unitLabel,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final entry in options.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (value) => setState(() => _unit = value ?? _unit),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: OperixColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
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
