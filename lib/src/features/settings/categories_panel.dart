import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/category_repository.dart';
import '../../domain/catalog_models.dart';
import 'settings_ui.dart';

/// Settings → Item categories. Bilingual (EN/AR) CRUD for product categories,
/// ported from the web tenant app's CategoriesSettings page.
class CategoriesPanel extends StatefulWidget {
  const CategoriesPanel({super.key});

  @override
  State<CategoriesPanel> createState() => _CategoriesPanelState();
}

class _CategoriesPanelState extends State<CategoriesPanel> {
  late CategoryRepository _repository;
  late Future<List<ProductCategory>> _future;
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repository = context.read<CategoryRepository>();
    _future = _repository.list();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    // Block body (not `=> _future = ...`): an arrow returns the assignment value
    // — a Future — which setState rejects, silently skipping the rebuild.
    setState(() {
      _future = _repository.list(search: _search.text.trim());
    });
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  Future<void> _create() async {
    final draft = await showCategoryDialog(context);
    if (draft == null || !mounted) return;
    await _runSave(() => _repository.create(draft), context.l10n.catCreated);
  }

  Future<void> _edit(ProductCategory category) async {
    final draft = await showCategoryDialog(context, category: category);
    if (draft == null || !mounted) return;
    await _runSave(
      () => _repository.update(category.id, draft),
      context.l10n.catUpdated,
    );
  }

  Future<void> _runSave(Future<Object?> Function() op, String okMessage) async {
    final l10n = context.l10n;
    try {
      await op();
      _reload();
      _toast(okMessage);
    } on CategoryException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(l10n.catalogSaveError('$e'));
    }
  }

  Future<void> _delete(ProductCategory category) async {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.catDeleteTitle),
        content: Text(l10n.catDeleteConfirm(category.displayName(arabic))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OperixColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(category.id);
      _reload();
      _toast(l10n.catDeleted);
    } on CategoryException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return SettingsCard(
      title: l10n.navItemCategories,
      subtitle: l10n.catSubtitle,
      trailing: FilledButton.icon(
        onPressed: _create,
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.catAdd),
        style: FilledButton.styleFrom(
          backgroundColor: OperixColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: l10n.catSearchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ProductCategory>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.catalogLoadError('${snapshot.error}')),
                );
              }
              final categories = snapshot.data ?? const [];
              if (categories.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      l10n.catEmpty,
                      style: const TextStyle(color: OperixColors.muted),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final category in categories)
                    _CategoryRow(
                      title: category.displayName(arabic),
                      subtitle: l10n.catProductCount(category.productsCount),
                      onEdit: () => _edit(category),
                      onDelete: () => _delete(category),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OperixColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: OperixColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OperixColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.edit,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            color: OperixColors.ink,
          ),
          IconButton(
            tooltip: context.l10n.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 19),
            color: OperixColors.danger,
          ),
        ],
      ),
    );
  }
}

/// Bilingual create/edit dialog. Returns a [CategoryDraft] or null on cancel.
Future<CategoryDraft?> showCategoryDialog(
  BuildContext context, {
  ProductCategory? category,
}) {
  return showDialog<CategoryDraft>(
    context: context,
    builder: (_) => _CategoryDialog(category: category),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});
  final ProductCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _en = TextEditingController(
    text: widget.category?.nameEn ?? '',
  );
  late final TextEditingController _ar = TextEditingController(
    text: widget.category?.nameAr ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _en.dispose();
    _ar.dispose();
    super.dispose();
  }

  void _submit() {
    final en = _en.text.trim();
    final ar = _ar.text.trim();
    if (en.isEmpty && ar.isEmpty) {
      setState(() => _error = context.l10n.catNameRequired);
      return;
    }
    Navigator.pop(context, CategoryDraft(nameEn: en, nameAr: ar));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.category == null ? l10n.catAdd : l10n.catEditTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: OperixColors.danger)),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _en,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.catNameEn,
                hintText: l10n.catNameHintEn,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ar,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: l10n.catNameAr,
                hintText: l10n.catNameHintAr,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.saveChanges)),
      ],
    );
  }
}
