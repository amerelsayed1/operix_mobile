import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)`.
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
