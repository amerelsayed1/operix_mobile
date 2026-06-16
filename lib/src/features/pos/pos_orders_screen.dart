import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/pos_repository.dart';
import 'sales_history_view.dart';

/// All POS orders (not scoped to a shift). Reuses [SalesHistoryView], which
/// loads real orders from the repository and opens their receipts. Replaces the
/// old hardcoded dashboard mock.
class PosOrdersScreen extends StatelessWidget {
  const PosOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalesHistoryView(
      repository: context.read<PosRepository>(),
      shiftId: null,
    );
  }
}
