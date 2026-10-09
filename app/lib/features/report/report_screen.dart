import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/insights.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../money/budget_screen.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snapAsync = ref.watch(moneySnapshotProvider);
    final entries = ref.watch(journalEntriesProvider).value ?? const [];
    final now = DateTime.now();
    final monthKey = toMonthKey(now);

    return snapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (snap) {
        final month = snap.inMonth(monthKey).toList();
        final monthIn = MoneySnapshot.sumOf(month, 'income');
        final monthOut = MoneySnapshot.sumOf(month, 'expense');
        final net = monthIn - monthOut;
        // Kategori yang punya pengeluaran atau budget bulan ini.
        final budgetRows =
            [
              for (final c in snap.categories.where((c) => c.kind == 'expense'))
                (
                  c,
                  snap.spentIn(c.id, monthKey),
                  snap.budgetFor(c.id, monthKey),
                ),
            ].where((r) => r.$2 > 0 || r.$3 > 0).toList()..sort(
              (a, b) => b.$2.compareTo(a.$2),
            );
        final insight = moodSpending(entries, snap);

        Widget row(
          String label,
          String value, {
          Color? color,
          bool last = false,
          bool bold = false,
        }) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: bold ? AppColors.ink : AppColors.muted,
                    fontWeight: bold ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 124),
          children: [
            ScreenHeader(
              overline: DateFormat('MMMM y', context.localeTag).format(now),
              title: l.navReport,
            ),
            const SizedBox(height: 16),
            _BudgetMood(
              hasSpending: monthOut > 0,
              hasBudget: budgetRows.any((r) => r.$3 > 0),
              overBudget: [
                for (final (cat, spent, budget) in budgetRows)
                  if (budget > 0 && spent > budget) categoryLabel(l, cat),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  row(l.income, rupiah(monthIn), color: AppColors.income),
                  row(l.expense, rupiah(monthOut), color: AppColors.expense),
                  row(
                    l.net,
                    '${net < 0 ? '−' : ''}${rupiah(net)}',
                    last: true,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.budgetPerCategory,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => BudgetScreen.open(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          textStyle: buttonTextStyle(
                            context,
                            const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        child: Text(l.manage),
                      ),
                    ],
                  ),
                  if (budgetRows.isEmpty) EmptyNote(l.reportEmpty),
                  for (final (cat, spent, budget) in budgetRows) ...[
                    const SizedBox(height: 10),
                    BudgetRow(category: cat, spent: spent, budget: budget),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MoodSpendingCard(good: insight.good, low: insight.low),
          ],
        );
      },
    );
  }
}

class _MoodSpendingCard extends StatelessWidget {
  const _MoodSpendingCard({required this.good, required this.low});

  final int? good;
  final int? low;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    const deep = Color(0xFF143F34);

    final text = switch ((good, low)) {
      (final g?, final b?) when b > g => l.insightSpendWhenLow,
      (_?, _?) => l.insightSpendWhenGood,
      _ => l.insightNeedMore,
    };

    Widget stat(String label, int? value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.bodySmall?.copyWith(color: AppColors.muted)),
            Text(
              value == null ? l.noData : rupiah(value),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.moodSpending,
            style: t.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: deep,
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stat(l.avgGoodMood, good),
                const SizedBox(width: 10),
                stat(l.avgLowMood, low),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(text, style: t.bodyMedium?.copyWith(color: deep)),
        ],
      ),
    );
  }
}

/// Kartu maskot di atas laporan: ringkasan kondisi budget bulan ini.
class _BudgetMood extends StatelessWidget {
  const _BudgetMood({
    required this.hasSpending,
    required this.hasBudget,
    required this.overBudget,
  });

  final bool hasSpending;
  final bool hasBudget;

  /// Nama kategori yang pengeluarannya melewati budget.
  final List<String> overBudget;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final (pose, tint, title, body) = !hasSpending
        ? (
            MascotPose.tidur,
            MascotTint.sky,
            l.mascotReportEmptyTitle,
            l.mascotReportEmptyBody,
          )
        : overBudget.isNotEmpty
        ? (
            MascotPose.sedih,
            MascotTint.rose,
            l.mascotBudgetOverTitle(overBudget.length),
            l.mascotBudgetOverBody(overBudget.join(', ')),
          )
        : !hasBudget
        ? (
            MascotPose.koin,
            MascotTint.lemon,
            l.mascotNoBudgetTitle,
            l.mascotNoBudgetBody,
          )
        : (
            MascotPose.senang,
            MascotTint.pink,
            l.mascotBudgetOkTitle,
            l.mascotBudgetOkBody,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Mascot(pose, size: 80),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(body, style: t.bodySmall?.copyWith(color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
