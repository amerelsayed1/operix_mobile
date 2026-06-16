import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/unit_repository.dart';
import '../../domain/catalog_models.dart';
import 'settings_ui.dart';

/// Settings → Units. Bilingual (EN/AR) CRUD for units of measure with a single
/// default, ported from the web tenant app's UnitsSettings page.
class UnitsPanel extends StatefulWidget {
  const UnitsPanel({super.key});

  @override
  State<UnitsPanel> createState() => _UnitsPanelState();
}

class _UnitsPanelState extends State<UnitsPanel> {
  late UnitRepository _repository;
  late Future<List<Unit>> _future;

  @override
  void initState() {
    super.initState();
    _repository = context.read<UnitRepository>();
    _future = _repository.list();
  }

  void _reload() {
    // Block body (not `=> _future = ...`): an arrow returns the assignment value
    // — a Future — which setState rejects, silently skipping the rebuild.
    setState(() {
      _future = _repository.list();
    });
  }

  Future<void> _create() async {
    final draft = await showUnitDialog(context);
    if (draft == null || !mounted) return;
    await _runSave(() => _repository.create(draft), context.l10n.unitCreated);
  }

  Future<void> _edit(Unit unit) async {
    final draft = await showUnitDialog(context, unit: unit);
    if (draft == null || !mounted) return;
    await _runSave(
      () => _repository.update(unit.id, draft),
      context.l10n.unitUpdated,
    );
  }

  Future<void> _runSave(Future<Object?> Function() op, String okMessage) async {
    final l10n = context.l10n;
    try {
      await op();
      _reload();
      _toast(okMessage);
    } on UnitException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(l10n.catalogSaveError('$e'));
    }
  }

  Future<void> _setDefault(Unit unit) async {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = unit.displayName(arabic);
    try {
      await _repository.setDefault(unit.id);
      _reload();
      _toast(l10n.unitDefaultSet(name));
    } on UnitException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _delete(Unit unit) async {
    final l10n = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unitDeleteTitle),
        content: Text(l10n.unitDeleteConfirm(unit.displayName(arabic))),
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
      await _repository.delete(unit.id);
      _reload();
      _toast(l10n.unitDeleted);
    } on UnitException catch (e) {
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
      title: l10n.navUnits,
      subtitle: l10n.unitSubtitle,
      trailing: FilledButton.icon(
        onPressed: _create,
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.unitAdd),
        style: FilledButton.styleFrom(
          backgroundColor: OperixColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      child: FutureBuilder<List<Unit>>(
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
          final units = snapshot.data ?? const [];
          if (units.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  l10n.unitEmpty,
                  style: const TextStyle(color: OperixColors.muted),
                ),
              ),
            );
          }
          return Column(
            children: [
              for (final unit in units)
                _UnitRow(
                  unit: unit,
                  title: unit.displayName(arabic),
                  onSetDefault: unit.isDefault ? null : () => _setDefault(unit),
                  onEdit: () => _edit(unit),
                  onDelete: () => _delete(unit),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.title,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final Unit unit;
  final String title;
  final VoidCallback? onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = (unit.shortCode ?? '').trim();
    final meta = <String>[
      if (code.isNotEmpty) code,
      unit.allowDecimal ? l10n.unitDecimalAllowed : l10n.unitIntegerOnly,
    ].join('  ·  ');
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: OperixColors.ink,
                        ),
                      ),
                    ),
                    if (unit.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 13,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.unitDefaultBadge,
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    color: OperixColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (onSetDefault != null)
            IconButton(
              tooltip: l10n.unitSetDefault,
              onPressed: onSetDefault,
              icon: const Icon(Icons.star_border, size: 19),
              color: const Color(0xFFD97706),
            ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            color: OperixColors.ink,
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 19),
            color: OperixColors.danger,
          ),
        ],
      ),
    );
  }
}

/// Bilingual create/edit dialog. Returns a [UnitDraft] or null on cancel.
Future<UnitDraft?> showUnitDialog(BuildContext context, {Unit? unit}) {
  return showDialog<UnitDraft>(
    context: context,
    builder: (_) => _UnitDialog(unit: unit),
  );
}

class _UnitDialog extends StatefulWidget {
  const _UnitDialog({this.unit});
  final Unit? unit;

  @override
  State<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<_UnitDialog> {
  late final TextEditingController _en = TextEditingController(
    text: widget.unit?.nameEn ?? '',
  );
  late final TextEditingController _ar = TextEditingController(
    text: widget.unit?.nameAr ?? '',
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.unit?.shortCode ?? '',
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.unit?.description ?? '',
  );
  late bool _allowDecimal = widget.unit?.allowDecimal ?? false;
  String? _error;

  @override
  void dispose() {
    _en.dispose();
    _ar.dispose();
    _code.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _submit() {
    final en = _en.text.trim();
    final ar = _ar.text.trim();
    if (en.isEmpty && ar.isEmpty) {
      setState(() => _error = context.l10n.unitNameRequired);
      return;
    }
    Navigator.pop(
      context,
      UnitDraft(
        nameEn: en,
        nameAr: ar,
        shortCode: _code.text.trim(),
        description: _desc.text.trim(),
        allowDecimal: _allowDecimal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.unit == null ? l10n.unitAdd : l10n.unitEditTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: OperixColors.danger),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _en,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.unitNameEn,
                  hintText: l10n.unitNameHintEn,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ar,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: l10n.unitNameAr,
                  hintText: l10n.unitNameHintAr,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                decoration: InputDecoration(
                  labelText: l10n.unitShortCodeLabel,
                  hintText: l10n.unitShortCodeHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.unitAllowDecimalLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: OperixColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.unitIntegerOnly),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.unitDecimalAllowed),
                  ),
                ],
                selected: {_allowDecimal},
                onSelectionChanged: (s) =>
                    setState(() => _allowDecimal = s.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _desc,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.unitDescriptionLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
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
