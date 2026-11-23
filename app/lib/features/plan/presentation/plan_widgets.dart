import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../providers.dart';
import '../domain/daily_plan.dart';

/// Satu baris rencana. Rencana besok ([checkable] false) belum bisa dicentang.
class PlanRow extends ConsumerWidget {
  const PlanRow({
    super.key,
    required this.plan,
    this.checkable = true,
    this.showDivider = true,
    this.onMenu,
  });

  final DailyPlan plan;
  final bool checkable;
  final bool showDivider;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final done = plan.doneAt != null;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.short,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? c.primary : Colors.transparent,
              border: Border.all(color: done ? c.primary : c.faint, width: 2),
            ),
            child: done
                ? Icon(Icons.check, size: 16, color: c.onPrimary)
                : null,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              plan.title,
              style: TextStyle(
                fontSize: AppFontSize.bodyLg,
                height: 1.45,
                color: done ? c.muted : c.ink,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: c.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: checkable
                ? Semantics(
                    checked: done,
                    child: InkWell(
                      onTap: () => ref
                          .read(planRepositoryProvider)
                          .setDone(plan.id, !done),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: row,
                    ),
                  )
                : row,
          ),
          if (onMenu != null)
            IconButton(
              tooltip: context.l10n.planMenu(plan.title),
              onPressed: onMenu,
              icon: Icon(Icons.more_vert, size: 20, color: c.muted),
            ),
        ],
      ),
    );
  }
}

/// Kolom "tambah rencana" dengan tombol +; Enter juga menambah.
class PlanAddField extends ConsumerStatefulWidget {
  const PlanAddField({
    super.key,
    required this.date,
    required this.label,
    required this.hint,
  });

  final String date;
  final String label;
  final String hint;

  @override
  ConsumerState<PlanAddField> createState() => _PlanAddFieldState();
}

class _PlanAddFieldState extends ConsumerState<PlanAddField> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _text.text.trim();
    if (title.isEmpty) return;
    _text.clear();
    // Tetap di kolom ini supaya bisa menulis beberapa rencana berturut-turut.
    _focus.requestFocus();
    await ref.read(planRepositoryProvider).add(title: title, date: widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: widget.label,
            child: TextField(
              controller: _text,
              focusNode: _focus,
              maxLength: planTitleMax,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onEditingComplete: _add,
              decoration: InputDecoration(
                hintText: widget.hint,
                counterText: '',
                isDense: true,
              ),
              style: const TextStyle(fontSize: AppFontSize.bodyLg),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        IconButton.filled(
          tooltip: widget.label,
          onPressed: _add,
          style: IconButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Ubah, pindah hari, atau hapus satu rencana.
class PlanEditSheet extends ConsumerStatefulWidget {
  const PlanEditSheet({super.key, required this.plan, required this.today});

  final DailyPlan plan;

  /// Hari ini (YYYY-MM-DD).
  final String today;

  static Future<void> open(
    BuildContext context, {
    required DailyPlan plan,
    required String today,
  }) => showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PlanEditSheet(plan: plan, today: today),
  );

  @override
  ConsumerState<PlanEditSheet> createState() => _PlanEditSheetState();
}

class _PlanEditSheetState extends ConsumerState<PlanEditSheet> {
  late final _text = TextEditingController(text: widget.plan.title);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _close(Future<void> Function() action) async {
    await action();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.read(planRepositoryProvider);
    final plan = widget.plan;
    final isToday = plan.planDate == widget.today;
    final target = isToday ? nextDay(widget.today) : widget.today;

    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Text(
            l.planEdit,
            style: const TextStyle(
              fontSize: AppFontSize.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _text,
            maxLength: planTitleMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.planField,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.arrow_forward),
            title: Text(isToday ? l.planMoveTomorrow : l.planMoveToday),
            onTap: () => _close(() => repo.move([plan.id], target)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: context.colors.expense,
            textColor: context.colors.expense,
            leading: const Icon(Icons.delete_outline),
            title: Text(l.delete),
            onTap: () => _close(() => repo.delete(plan.id)),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_text.text.trim().isEmpty) return;
                    _close(() => repo.rename(plan.id, _text.text));
                  },
                  child: Text(l.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
