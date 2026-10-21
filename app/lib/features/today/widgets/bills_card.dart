import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/db/app_database.dart';
import '../../../providers.dart';
import '../../money/bill_detail_sheet.dart';
import '../../money/bill_form_sheet.dart';

class BillsCard extends ConsumerWidget {
  const BillsCard({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final bills = ref.watch(unpaidBillsProvider).value ?? const [];
    final snap = ref.watch(moneySnapshotProvider).value;

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
                    const Text('🔔 ', style: TextStyle(fontSize: 15)),
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
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const SizedBox(height: 10),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak ada tagihan yang belum dibayar. Bersih! 🎉',
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
            )
          else
            for (var i = 0; i < bills.length; i++) ...[
              if (i > 0) Divider(color: context.colors.divider, height: 16),
              _buildBillRow(context, ref, bills[i], snap),
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
      borderRadius: BorderRadius.circular(12),
      onTap: () => BillDetailSheet.open(context, bill: bill, now: now, moneySnap: snap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.subtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📄', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
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
                      fontSize: 11.5,
                    ),
                  ),
                  if (wallet != null)
                    Text(
                      'Bayar via: ${wallet.name}',
                      style: t.bodySmall?.copyWith(
                        color: context.colors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rupiah(bill.amount),
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
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
