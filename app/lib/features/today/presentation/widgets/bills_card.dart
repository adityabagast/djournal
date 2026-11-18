import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/format.dart';
import '../../../../core/theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../providers.dart';
import '../../../money/presentation/bill_detail_sheet.dart';
import '../../../money/presentation/bill_form_sheet.dart';
import '../../../../core/tokens.dart';

class BillsCard extends ConsumerWidget {
  const BillsCard({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final bills = ref.watch(unpaidBillsProvider).value ?? const [];
    final snap = ref.watch(moneySnapshotProvider).value;
    final hide = ref.watch(hideAmountsProvider).value ?? false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🔔 ', style: TextStyle(fontSize: AppFontSize.title)),
                    Flexible(
                      child: Text(
                        'Tagihan Mendatang',
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => BillFormSheet.open(context),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs),
                  child: Text(
                    '+ Tambah',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text(
                'Tidak ada tagihan yang belum dibayar. Bersih! 🎉',
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
            )
          else
            for (var i = 0; i < bills.length; i++) ...[
              if (i > 0) Divider(color: context.colors.divider, height: 16),
              _buildBillRow(context, ref, bills[i], snap, hide),
            ],
        ],
      ),
    );
  }

  Widget _buildBillRow(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
    dynamic snap,
    bool hide,
  ) {
    final t = Theme.of(context).textTheme;
    final due = DateTime.tryParse(bill.dueDate);
    final daysLeft = due != null
        ? due.difference(DateTime(now.year, now.month, now.day)).inDays
        : 99;

    final isUrgent = daysLeft <= 2;
    final isWarn = daysLeft <= 7;

    final dueText = daysLeft == 0
        ? 'Jatuh tempo HARI INI!'
        : daysLeft < 0
            ? 'Lewat tempo ${daysLeft.abs()} hari!'
            : isUrgent
                ? '⚡ $daysLeft hari lagi (${DateFormat('d MMM', 'id').format(due!)})'
                : '$daysLeft hari lagi (${DateFormat('d MMM', 'id').format(due!)})';

    final Color dueColor = isUrgent
        ? context.colors.expense
        : isWarn
            ? context.colors.warning
            : context.colors.muted;

    final wallet = bill.walletId != null ? snap?.walletById[bill.walletId!] : null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => BillDetailSheet.open(context, bill: bill, now: now, moneySnap: snap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.subtle,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Center(
                child: Text('📄', style: TextStyle(fontSize: AppFontSize.heading)),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    dueText,
                    style: t.bodySmall?.copyWith(
                      color: dueColor,
                      fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                  if (wallet != null)
                    Text(
                      'Bayar via: ${wallet.name}',
                      style: t.bodySmall?.copyWith(
                        color: context.colors.muted,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rupiah(bill.amount, hide: hide),
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.xs),
                SizedBox(
                  height: 28,
                  child: FilledButton.tonal(
                    onPressed: () => BillDetailSheet.open(
                      context,
                      bill: bill,
                      now: now,
                      moneySnap: snap,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      textStyle: const TextStyle(fontSize: AppFontSize.caption, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Detail'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
