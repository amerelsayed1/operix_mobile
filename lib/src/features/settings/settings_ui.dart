import 'package:flutter/material.dart';

import '../../app/operix_theme.dart';

/// Shared building blocks for the Settings area so every panel matches the
/// Operix web look: soft-bordered white cards, labelled inputs and a breadcrumb.

const kFieldLabelStyle = TextStyle(
  color: OperixColors.muted,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

/// Rounded, lightly-bordered input decoration used across the settings forms.
InputDecoration kFieldDecoration(String? hint) {
  const radius = BorderRadius.all(Radius.circular(10));
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: OperixColors.subtle),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: border(OperixColors.border),
    border: border(OperixColors.border),
    focusedBorder: border(OperixColors.primary),
    errorBorder: border(OperixColors.danger),
    focusedErrorBorder: border(OperixColors.danger),
  );
}

/// A field with a label above it and an optional required asterisk.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: kFieldLabelStyle,
              ),
            ),
            if (required)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: OperixColors.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: kFieldDecoration(hint),
        ),
      ],
    );
  }
}

/// A white settings card with a title, optional subtitle and a body.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OperixColors.border),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: OperixColors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: OperixColors.muted,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// Breadcrumb shown above settings content (e.g. Dashboard / Settings / Roles).
class SettingsBreadcrumb extends StatelessWidget {
  const SettingsBreadcrumb({required this.trail, super.key});

  final List<String> trail;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < trail.length; i++) {
      final isLast = i == trail.length - 1;
      children.add(
        Text(
          trail[i],
          style: TextStyle(
            color: isLast ? OperixColors.ink : OperixColors.muted,
            fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      );
      if (!isLast) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: TextStyle(color: OperixColors.subtle, fontSize: 13.5),
            ),
          ),
        );
      }
    }
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: children);
  }
}
