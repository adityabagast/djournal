import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';

/// Atur budget bulanan per kategori pengeluaran.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const BudgetScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;
    final monthKey = toMonthKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.budget,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  l.budgetSubtitle,
                  style: t.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.budgetTotal,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        rupiah(snap.totalBudget(monthKey)),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (final c in snap.categories.where(
                        (c) => c.kind == 'expense',
                      ))
                        InkWell(
                          onTap: () => _edit(context, ref, c, snap, monthKey),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: BudgetRow(
                              category: c,
                              spent: snap.spentIn(c.id, monthKey),
                              budget: snap.budgetFor(c.id, monthKey),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Category category,
    MoneySnapshot snap,
    String monthKey,
  ) async {
    final l = context.l10n;
    final current = snap.budgetFor(category.id, monthKey);
    final controller = TextEditingController(
      text: current > 0 ? thousands(current) : '',
    );
    final monthName = DateFormat(
      'MMMM y',
      context.localeTag,
    ).format(DateTime.now());

    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(categoryLabel(l, category)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration: InputDecoration(
                labelText: l.budgetLimit,
                hintText: l.budgetHint,
                prefixText: 'Rp ',
              ),
              onSubmitted: (v) => Navigator.pop(ctx, parseAmount(v)),
            ),
            const SizedBox(height: 8),
            Text(
              l.budgetAppliesFrom(monthName),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, parseAmount(controller.text)),
            child: Text(l.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount == current) return;
    await ref
        .read(moneyRepositoryProvider)
        .setBudget(
          categoryId: category.id,
          startMonth: monthKey,
          amount: amount,
        );
  }
}

/// Nama kategori, "terpakai / budget", progress bar, dan catatan status.
/// Dipakai di layar Budget dan Laporan.
class BudgetRow extends StatelessWidget {
  const BudgetRow({
    super.key,
    required this.category,
    required this.spent,
    required this.budget,
    this.trailing,
  });

  final Category category;
  final int spent;
  final int budget;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasBudget = budget > 0;
    final over = hasBudget && spent > budget;
    final pct = hasBudget ? (spent * 100 / budget).round() : 0;
    final catColor = hexColor(category.color);

    final note = over
        ? l.overBudget(rupiah(spent - budget))
        : (hasBudget ? l.budgetUsedPct(pct) : l.noBudget);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryLabel(l, category),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    hasBudget
                        ? '${rupiah(spent)} / ${rupiah(budget)}'
                        : rupiah(spent),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hasBudget
                      ? (spent / budget).clamp(0, 1).toDouble()
                      : (spent > 0 ? 1 : 0),
                  minHeight: 8,
                  backgroundColor: AppColors.track,
                  color: over ? AppColors.expense : catColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  color: over ? AppColors.expense : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
