import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../domain/models/global_budget.dart';
import '../../../domain/models/money_snapshot.dart';
import '../../../providers.dart';

class BudgetWarningBanner extends ConsumerWidget {
  const BudgetWarningBanner({
    super.key,
    required this.snapshot,
    required this.now,
  });

  final MoneySnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final globalBudget = ref.watch(globalBudgetProvider);
    final unpaidBills = ref.watch(unpaidBillsProvider).value ?? const [];
    final hide = ref.watch(hideAmountsProvider).value ?? false;

    // 1. Cek peringatan tagihan jatuh tempo (H-2 atau lewat tempo)
    final todayStr = toLocalDate(now);
    final urgentBills = unpaidBills.where((b) {
      final due = DateTime.tryParse(b.dueDate);
      if (due == null) return false;
      final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff <= 2;
    }).toList();

    if (urgentBills.isNotEmpty) {
      final bill = urgentBills.first;
      final overdue = bill.dueDate.compareTo(todayStr) < 0;
      final when = overdue
          ? 'sudah lewat jatuh tempo'
          : bill.dueDate == todayStr
              ? 'jatuh tempo HARI INI'
              : 'segera jatuh tempo';
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.isDark ? const Color(0xFF381A1A) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.expense.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡ ', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overdue ? 'Tagihan Lewat Jatuh Tempo!' : 'Tagihan Segera Jatuh Tempo!',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill.title} (${rupiah(bill.amount, hide: hide)}) $when.',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Cek peringatan budget harian / bulanan
    final todaySpent = MoneySnapshot.sumOf(snapshot.onDate(todayStr), 'expense');
    final dailyLimit = globalBudget.dailyLimit;
    final dailyLevel = GlobalBudget.alertLevelFor(todaySpent, dailyLimit);

    if (dailyLevel == BudgetAlertLevel.danger) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.isDark ? const Color(0xFF381A1A) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.expense.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚨 ', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Harian Terlampaui!',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.expense,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pengeluaran hari ini sudah melebihi batas jatah sebesar ${rupiah(todaySpent - dailyLimit, hide: hide)}.',
                    style: t.bodySmall?.copyWith(color: context.colors.expense),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (dailyLevel == BudgetAlertLevel.warning) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.warnSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.warning.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ ', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mendekati Batas Budget Harian',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sisa jatah belanja hari ini tinggal ${rupiah(dailyLimit - todaySpent, hide: hide)}.',
                    style: t.bodySmall?.copyWith(color: context.colors.warning),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
