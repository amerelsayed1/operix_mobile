import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/operix_theme.dart';
import '../../data/product_repository.dart';
import '../../domain/inventory_models.dart';

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
  List<String> _categories = [];

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
    try {
      final categories = await widget.repository.categories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {}
    if (!widget.isEditing) {
      try {
        final sku = await widget.repository.suggestSku();
        if (mounted && _sku.text.isEmpty) _sku.text = sku;
      } catch (_) {}
    }
  }

  String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

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
      costPrice: double.tryParse(_costPrice.text.trim()) ?? 0,
      sellingPrice: double.tryParse(_sellingPrice.text.trim()) ?? 0,
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
      setState(() => _error = 'Could not save product: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = {..._unitOptions};
    return Scaffold(
      backgroundColor: OperixColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit product' : 'New product'),
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
                    title: 'Product details',
                    children: [
                      _field(
                        controller: _name,
                        label: 'Product name *',
                        hint: 'e.g. Wireless Keyboard',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              controller: _sku,
                              label: 'SKU *',
                              hint: 'Stock keeping unit',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'SKU is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              controller: _barcode,
                              label: 'Barcode',
                              hint: 'Optional',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _categoryField()),
                          const SizedBox(width: 16),
                          Expanded(child: _unitField(units)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Pricing',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numberField(
                              controller: _costPrice,
                              label: 'Cost price',
                              prefix: 'EGP ',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _numberField(
                              controller: _sellingPrice,
                              label: 'Selling price *',
                              prefix: 'EGP ',
                              validator: (v) {
                                final value = double.tryParse((v ?? '').trim());
                                if (value == null) return 'Enter a valid price';
                                if (value < 0) return 'Cannot be negative';
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
                    title: 'Inventory',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numberField(
                              controller: _stock,
                              label: widget.isEditing
                                  ? 'Stock on hand'
                                  : 'Opening stock',
                              integer: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _numberField(
                              controller: _minStock,
                              label: 'Minimum stock alert',
                              integer: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Inactive products are hidden from the POS',
                        ),
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
                        child: const Text('Cancel'),
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
                          widget.isEditing ? 'Save changes' : 'Create product',
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

  Set<String> get _unitOptions => {...kProductUnits, _unit};

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

  Widget _categoryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _category,
        decoration: InputDecoration(
          labelText: 'Category',
          hintText: 'e.g. Electronics',
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: _categories.isEmpty
              ? null
              : PopupMenuButton<String>(
                  tooltip: 'Pick existing',
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) => _category.text = value,
                  itemBuilder: (context) => [
                    for (final c in _categories)
                      PopupMenuItem(value: c, child: Text(c)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _unitField(Set<String> units) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _unit,
        decoration: const InputDecoration(
          labelText: 'Unit',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final u in units) DropdownMenuItem(value: u, child: Text(u)),
        ],
        onChanged: (value) => setState(() => _unit = value ?? 'Piece'),
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
