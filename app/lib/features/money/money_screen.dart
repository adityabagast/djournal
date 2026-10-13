import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../search/search_screen.dart';
import 'tx_form_screen.dart';
import 'wallet_form_sheet.dart';
import 'wallets_screen.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  /// null = semua, 'expense', 'income', 'transfer'
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snapAsync = ref.watch(moneySnapshotProvider);
    final now = DateTime.now();
    final monthKey = toMonthKey(now);

    return snapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (snap) {
        final month = snap.inMonth(monthKey).toList();
        final filtered = snap.transactions
            .where((tx) => _filter == null || tx.type == _filter)
            .toList();
        final groups = <String, List<MoneyTx>>{};
        for (final tx in filtered) {
          groups.putIfAbsent(tx.localDate, () => []).add(tx);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 124),
          children: [
            ScreenHeader(
              overline: DateFormat('MMMM y', context.localeTag).format(now),
              title: l.navMoney,
              trailing: const SearchButton(),
            ),
            const SizedBox(height: 16),
            _BalanceCard(
              total: snap.totalBalance,
              monthIn: MoneySnapshot.sumOf(month, 'income'),
              monthOut: MoneySnapshot.sumOf(month, 'expense'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.wallets,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => WalletsScreen.open(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 8, right: 0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.manageAction),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, w) in snap.wallets.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _WalletCard(
                      name: w.name,
                      balance: snap.balanceOf(w.id),
                      onTap: () => WalletFormSheet.open(context, existing: w),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Empat chip tidak muat satu baris di HP: geser ke samping.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  for (final (key, text) in [
                    (null, l.filterAll),
                    ('expense', l.expense),
                    ('income', l.income),
                    ('transfer', l.transfer),
                  ])
                    _FilterChip(
                      label: text,
                      selected: _filter == key,
                      onTap: () => setState(() => _filter = key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (snap.transactions.isEmpty)
              MascotEmpty(
                pose: MascotPose.koin,
                tint: MascotTint.lemon,
                title: l.mascotTxEmptyTitle,
                message: l.mascotTxEmptyBody,
                size: 160,
                action: FilledButton(
                  onPressed: () => TxFormScreen.open(context),
                  child: Text(l.mascotRecordTx),
                ),
              )
            else if (groups.isEmpty)
              MascotEmpty(
                pose: MascotPose.mencari,
                tint: MascotTint.sky,
                title: l.mascotFilterEmptyTitle,
                message: l.mascotFilterEmptyBody,
                size: 140,
              ),
            for (final entry in groups.entries) ...[
              _DayHeader(
                label: dayLabel(context, entry.key),
                outTotal: MoneySnapshot.sumOf(entry.value, 'expense'),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++)
                      TxRow(
                        tx: entry.value[i],
                        snapshot: snap,
                        showDivider: i < entry.value.length - 1,
                        onTap: () => TxFormScreen.open(
                          context,
                          existing: entry.value[i],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.monthIn,
    required this.monthOut,
  });

  final int total;
  final int monthIn;
  final int monthOut;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    Widget stat(String label, int value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.onHero.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: t.bodySmall?.copyWith(color: context.colors.onHeroMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rupiah(value),
                style: t.bodyMedium?.copyWith(
                  color: context.colors.onHero,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.hero,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.totalBalance,
            style: t.bodySmall?.copyWith(color: context.colors.onHeroMuted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${total < 0 ? '−' : ''}${rupiah(total)}',
              style: t.headlineMedium?.copyWith(
                color: context.colors.onHero,
                fontWeight: FontWeight.w700,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat(l.income, monthIn),
              const SizedBox(width: 12),
              stat(l.expense, monthOut),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.name,
    required this.balance,
    required this.onTap,
  });

  final String name;
  final int balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(
                  color: context.colors.muted,
                  fontSize: 13,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${balance < 0 ? '−' : ''}${rupiah(balance)}',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: context.colors.primary,
      backgroundColor: context.colors.surface,
      side: BorderSide(
        color: selected ? context.colors.primary : context.colors.line,
      ),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? context.colors.onPrimary : context.colors.ink,
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.outTotal});

  final String label;
  final int outTotal;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.colors.muted, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (outTotal > 0)
            Text(
              '−${rupiah(outTotal)}',
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
