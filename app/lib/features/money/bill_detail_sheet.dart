import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';
import 'bill_form_sheet.dart';

/// Sheet detail tagihan: info lengkap + aksi Bayar / Edit / Hapus.
class BillDetailSheet extends ConsumerWidget {
  const BillDetailSheet({
    super.key,
    required this.bill,
    required this.now,
    this.moneySnap,
  });

  final Bill bill;
  final DateTime now;
  final dynamic moneySnap;

  static Future<void> open(
    BuildContext context, {
    required Bill bill,
    required DateTime now,
    dynamic moneySnap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BillDetailSheet(bill: bill, now: now, moneySnap: moneySnap),
    );
  }

  int get _daysLeft {
    final due = DateTime.tryParse(bill.dueDate);
    if (due == null) return 99;
    return due.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get _isUrgent => !bill.isPaid && _daysLeft <= 2;

  String get _dueText {
    final due = DateTime.tryParse(bill.dueDate);
    if (bill.isPaid) {
      return due != null ? DateFormat('d MMM yyyy', 'id').format(due) : bill.dueDate;
    }
    if (_daysLeft == 0) return 'Jatuh tempo HARI INI';
    if (_daysLeft < 0) return 'Lewat tempo ${_daysLeft.abs()} hari';
    final dateStr = due != null ? DateFormat('d MMM', 'id').format(due) : bill.dueDate;
    return '$_daysLeft hari lagi ($dateStr)';
  }

  String get _repeatLabel => switch (bill.repeatInterval) {
        'monthly' => 'Bulanan',
        'yearly' => 'Tahunan',
        'once' => 'Sekali',
        _ => bill.repeatInterval == null ? 'Sekali' : bill.repeatInterval!,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final wallet =
        bill.walletId != null ? moneySnap?.walletById[bill.walletId!] : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Detail Tagihan',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola tagihan ini: bayar, ubah, atau hapus.',
              style: t.bodySmall?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.subtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('📄', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rupiah(bill.amount),
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bill.isPaid
                          ? context.colors.income.withValues(alpha: 0.14)
                          : _isUrgent
                              ? context.colors.expense.withValues(alpha: 0.14)
                              : context.colors.warnSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      bill.isPaid
                          ? 'Lunas'
                          : _isUrgent
                              ? (_daysLeft <= 0 ? 'Hari ini' : '$_daysLeft hari')
                              : '$_daysLeft hari',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: bill.isPaid
                            ? context.colors.income
                            : _isUrgent
                                ? context.colors.expense
                                : context.colors.onWarnSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _kv(context, 'Jatuh tempo', _dueText),
            _kv(context, 'Rencana bayar', wallet?.name ?? '—'),
            _kv(context, 'Pengulangan', _repeatLabel),
            _kv(context, 'Status', bill.isPaid ? 'Sudah dibayar' : 'Belum dibayar'),
            const SizedBox(height: 16),
            if (bill.isPaid)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.expense,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _confirmDelete(context, ref),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pay(context, ref);
                      },
                      child: const Text('Bayar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await BillFormSheet.open(context, existing: bill);
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.expense.withValues(alpha: 0.12),
                        foregroundColor: context.colors.expense,
                      ),
                      onPressed: () => _confirmDelete(context, ref),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: t.bodySmall?.copyWith(color: context.colors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final snap = moneySnap;
    final activeWallets = (snap?.wallets as List<Wallet>?) ?? const [];
    var selectedWalletId = bill.walletId ?? activeWallets.firstOrNull?.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Bayar Tagihan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konfirmasi pembayaran ${bill.title} sebesar ${rupiah(bill.amount)}?'),
              const SizedBox(height: 14),
              if (activeWallets.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedWalletId,
                  decoration: const InputDecoration(labelText: 'Sumber Dana'),
                  items: [
                    for (final w in activeWallets)
                      DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${rupiah(snap?.balanceOf(w.id) ?? 0)})'),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedWalletId = val);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bayar Sekarang'),
            ),
          ],
        ),
      ),
    );
    final walletId = selectedWalletId;
    if (ok != true || walletId == null) return;

    final next = await ref.read(billRepositoryProvider).payBill(
          billId: bill.id,
          walletId: walletId,
        );
    if (context.mounted) {
      final nextDue = next == null ? null : DateTime.tryParse(next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextDue == null
                ? 'Tagihan ${bill.title} lunas!'
                : 'Tagihan ${bill.title} dibayar. Jatuh tempo berikutnya '
                    '${DateFormat('d MMM yyyy', 'id').format(nextDue)}.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tagihan?'),
        content: Text(
          '${bill.title} (${rupiah(bill.amount)}) akan dihapus dari daftar. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(billRepositoryProvider).deleteBill(bill.id);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tagihan ${bill.title} dihapus')),
      );
    }
  }
}
