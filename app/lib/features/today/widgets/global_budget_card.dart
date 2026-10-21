import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../domain/models/global_budget.dart';
import '../../../domain/models/money_snapshot.dart';
import '../../../providers.dart';
import '../../money/global_budget_sheet.dart';

class GlobalBudgetCard extends ConsumerWidget {
  const GlobalBudgetCard({
    super.key,
    required this.snapshot,
    required this.now,
    this.hideAmounts = false,
  });

  final MoneySnapshot snapshot;
  final DateTime now;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final period = ref.watch(budgetPeriodProvider);
    final globalBudget = ref.watch(globalBudgetProvider);

    final todayStr = toLocalDate(now);
    final monthKey = toMonthKey(now);

    // Hitung pengeluaran berdasarkan periode
    final int spent;
    final int limit;

    switch (period) {
      case BudgetPeriod.daily:
        spent = MoneySnapshot.sumOf(snapshot.onDate(todayStr), 'expense');
        limit = globalBudget.dailyLimit;
        break;
      case BudgetPeriod.weekly:
        // Hitung pengeluaran minggu ini (Mulai Senin)
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        var weekTotal = 0;
        for (var i = 0; i < 7; i++) {
          final d = startOfWeek.add(Duration(days: i));
          weekTotal += MoneySnapshot.sumOf(snapshot.onDate(toLocalDate(d)), 'expense');
        }
        spent = weekTotal;
        limit = globalBudget.weeklyLimit;
        break;
      case BudgetPeriod.monthly:
        spent = MoneySnapshot.sumOf(snapshot.inMonth(monthKey), 'expense');
        limit = globalBudget.monthlyLimit > 0
            ? globalBudget.monthlyLimit
            : snapshot.totalBudget(monthKey);
        break;
    }

    final alertLevel = GlobalBudget.alertLevelFor(spent, limit);
    final double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final int pct = limit > 0 ? ((spent / limit) * 100).round() : 0;
    final int remaining = limit - spent;

    Color progressColor;
    switch (alertLevel) {
      case BudgetAlertLevel.safe:
        progressColor = context.colors.primary;
        break;
      case BudgetAlertLevel.warning:
        progressColor = context.colors.warning;
        break;
      case BudgetAlertLevel.danger:
        progressColor = context.colors.expense;
        break;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Budget Global',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => GlobalBudgetSheet.open(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Atur Target',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented Switcher
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.colors.subtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.line),
            ),
            child: Row(
              children: [
                _buildSegment(context, ref, 'Harian', BudgetPeriod.daily, period),
                _buildSegment(context, ref, 'Mingguan', BudgetPeriod.weekly, period),
                _buildSegment(context, ref, 'Bulanan', BudgetPeriod.monthly, period),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                rupiah(spent, hide: hideAmounts),
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                limit > 0 ? 'dari ${rupiah(limit, hide: hideAmounts)}' : 'belum ada target',
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
              const Spacer(),
              if (limit > 0)
                Text(
                  '$pct%',
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
            ],
          ),
          if (limit > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: context.colors.track,
                color: progressColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (remaining >= 0)
                  Text(
                    'Sisa jatah: ${rupiah(remaining, hide: hideAmounts)}',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Overbudget: ${rupiah(remaining.abs(), hide: hideAmounts)}!',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.expense,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (alertLevel == BudgetAlertLevel.warning)
                  Text(
                    '⚠️ Mendekati batas',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (alertLevel == BudgetAlertLevel.danger)
                  Text(
                    '🚨 Budget terlampaui',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.expense,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Tekan "Atur Target" di atas untuk menetapkan batas anggaran.',
              style: t.bodySmall?.copyWith(color: context.colors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    WidgetRef ref,
    String label,
    BudgetPeriod target,
    BudgetPeriod current,
  ) {
    final isSelected = target == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(budgetPeriodProvider.notifier).setPeriod(target),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? context.colors.ink : context.colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
