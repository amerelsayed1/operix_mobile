import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/operix_theme.dart';
import '../../data/pos_repository.dart';
import 'pos_controller.dart';
import 'pos_terminal.dart';
import 'sales_history_view.dart';
import 'shift_views.dart';

/// Full-screen POS module. Gated on an open cashier shift; hosts the selling
/// terminal and the sales-history view, and owns the [PosController].
class PosWorkspace extends StatefulWidget {
  const PosWorkspace({super.key});

  @override
  State<PosWorkspace> createState() => _PosWorkspaceState();
}

class _PosWorkspaceState extends State<PosWorkspace> {
  late final PosController _controller;
  bool _resolvingShift = true;
  int _historyTick = 0;
  int _viewIndex = 0; // 0 = terminal, 1 = history

  @override
  void initState() {
    super.initState();
    _controller = PosController(repository: context.read<PosRepository>());
    _controller.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveShift());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveShift() async {
    final session = context.read<AppSession>();
    if (session.shift == null && session.user != null) {
      try {
        final shift = await context.read<PosRepository>().activeShift(
          session.user!.id,
        );
        if (shift != null && mounted) session.setShift(shift);
      } catch (_) {
        // Ignored: cashier can open a fresh shift manually.
      }
    }
    if (mounted) setState(() => _resolvingShift = false);
  }

  Future<void> _closeShift() async {
    final session = context.read<AppSession>();
    final shift = session.shift;
    if (shift == null) return;
    final closed = await showCloseShiftDialog(
      context,
      context.read<PosRepository>(),
      shift,
    );
    if (closed != null && mounted) {
      _controller.clearCart();
      session.setShift(null);
      setState(() => _viewIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvingShift) {
      return const Center(child: CircularProgressIndicator());
    }

    final session = context.watch<AppSession>();
    if (session.shift == null) {
      return const OpenShiftView();
    }

    return ChangeNotifierProvider<PosController>.value(
      value: _controller,
      child: Column(
        children: [
          _ShiftBar(
            shiftNumber: session.shift!.shiftNumber,
            openedAt: session.shift!.openedAt,
            viewIndex: _viewIndex,
            onViewChanged: (index) => setState(() => _viewIndex = index),
            onClose: _closeShift,
          ),
          Expanded(
            child: IndexedStack(
              index: _viewIndex,
              children: [
                PosTerminal(
                  onSaleComplete: () => setState(() => _historyTick++),
                ),
                SalesHistoryView(
                  repository: context.read<PosRepository>(),
                  shiftId: session.shift!.id,
                  refreshTick: _historyTick,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftBar extends StatelessWidget {
  const _ShiftBar({
    required this.shiftNumber,
    required this.openedAt,
    required this.viewIndex,
    required this.onViewChanged,
    required this.onClose,
  });

  final String shiftNumber;
  final DateTime openedAt;
  final int viewIndex;
  final ValueChanged<int> onViewChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: OperixColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.point_of_sale,
            color: OperixColors.tealDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift $shiftNumber',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                'Opened ${DateFormat('MMM d, HH:mm').format(openedAt)}',
                style: const TextStyle(color: OperixColors.muted, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Terminal'),
                icon: Icon(Icons.grid_view),
              ),
              ButtonSegment(
                value: 1,
                label: Text('History'),
                icon: Icon(Icons.receipt_long),
              ),
            ],
            selected: {viewIndex},
            onSelectionChanged: (selected) => onViewChanged(selected.first),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Close shift'),
          ),
        ],
      ),
    );
  }
}
