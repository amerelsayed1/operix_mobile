import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:operix_mobile/l10n/app_localizations.dart';
import 'package:operix_mobile/src/data/demo_unit_repository.dart';
import 'package:operix_mobile/src/data/unit_repository.dart';
import 'package:operix_mobile/src/features/settings/units_panel.dart';

Widget _harness(UnitRepository repo) {
  return Provider<UnitRepository>.value(
    value: repo,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SingleChildScrollView(child: UnitsPanel())),
    ),
  );
}

void main() {
  testWidgets('deleting a unit removes it from the list', (tester) async {
    await tester.pumpWidget(_harness(DemoUnitRepository()));
    await tester.pumpAndSettle();

    // Demo seed: Piece (default), Box, Kg, Liter.
    expect(find.text('Box'), findsOneWidget);

    // Tap the delete icon on the Box row.
    final boxRow = find
        .ancestor(of: find.text('Box'), matching: find.byType(Container))
        .first;
    await tester.tap(
      find.descendant(of: boxRow, matching: find.byIcon(Icons.delete_outline)),
    );
    await tester.pumpAndSettle();

    // Confirm in the delete dialog.
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // The list must refresh: Box gone, the rest remain. (Regression test for the
    // `setState(() => _future = ...)` arrow bug that silently skipped rebuilds.)
    expect(find.text('Box'), findsNothing);
    expect(find.text('Piece'), findsOneWidget);
    expect(find.text('Kg'), findsOneWidget);
  });
}
