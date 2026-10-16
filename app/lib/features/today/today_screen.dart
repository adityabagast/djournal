import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/journal_repository.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../journal/entry_form_screen.dart';
import '../journal/entry_rows.dart';
import '../money/tx_form_screen.dart';
import '../money/wallets_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snapAsync = ref.watch(moneySnapshotProvider);
    final entries = ref.watch(journalEntriesProvider).value ?? const [];
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;
    final now = DateTime.now();
    final today = toLocalDate(now);

    return snapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (snap) {
        final todayTx = snap.onDate(today).toList();
        final todayOut = MoneySnapshot.sumOf(todayTx, 'expense');

        // Timeline: entri jurnal dan transaksi hari ini, urut jam terbaru dulu (descending).
        final timeline = <(String, Widget Function(bool divider))>[
          for (final e in entries.where((e) => e.entryDate == today))
            (
              entrySortKey(e),
              (divider) => EntryTimelineRow(
                entry: e,
                showDivider: divider,
                onTap: () => EntryFormScreen.open(context, existing: e),
              ),
            ),
          for (final tx in todayTx)
            (
              hhmm(tx.occurredAt),
              (divider) => TxRow(
                tx: tx,
                snapshot: snap,
                leadingTime: true,
                showDivider: divider,
                onTap: () => TxFormScreen.open(context, existing: tx),
              ),
            ),
        ]..sort((a, b) => b.$1.compareTo(a.$1));
        final monthOut = MoneySnapshot.sumOf(
          snap.inMonth(toMonthKey(now)),
          'expense',
        );
        final budget = snap.totalBudget(toMonthKey(now));

        final spentCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l.todaySpent,
                              style: t.bodySmall?.copyWith(
                                color: context.colors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => ref
                                  .read(settingsRepositoryProvider)
                                  .set('hide_amounts', (!hideAmounts).toString()),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  hideAmounts
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 16,
                                  color: context.colors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rupiah(todayOut, hide: hideAmounts),
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        if (budget == 0)
                          Text(
                            l.monthSpent(rupiah(monthOut, hide: hideAmounts)),
                            style: t.bodySmall?.copyWith(
                              color: context.colors.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => TxFormScreen.open(context),
                    child: Text(l.record),
                  ),
                ],
              ),
              if (budget > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (monthOut / budget).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: context.colors.track,
                    color: monthOut > budget
                        ? context.colors.expense
                        : context.colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.budgetUsage(
                    DateFormat('MMMM', context.localeTag).format(now),
                    (monthOut * 100 / budget).round(),
                    rupiah((budget - monthOut).clamp(0, budget), hide: hideAmounts),
                  ),
                  style: t.bodySmall?.copyWith(
                    color: context.colors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );

        final timelineCard = AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.todayTimeline,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => EntryFormScreen.open(context),
                    style: TextButton.styleFrom(
                      backgroundColor: context.colors.primarySoft,
                      foregroundColor: context.colors.primary,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: buttonTextStyle(
                        context,
                        const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l.write),
                  ),
                ],
              ),
              if (timeline.isEmpty)
                MascotEmpty(
                  pose: MascotPose.halo,
                  tint: MascotTint.mint,
                  title: l.mascotTodayEmptyTitle,
                  message: l.timelineEmpty,
                  size: 130,
                ),
              for (var i = 0; i < timeline.length; i++)
                timeline[i].$2(i < timeline.length - 1),
            ],
          ),
        );

        return ListView(
          padding: context.screenPadding,
          children: [
            ScreenHeader(
              overline: DateFormat(
                'EEEE, d MMMM y',
                context.localeTag,
              ).format(now),
              title: l.navToday,
              trailing: Row(
                spacing: 8,
                children: [
                  const SearchButton(),
                  if (!context.isWide)
                    IconButton.outlined(
                      tooltip: l.settings,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.surface,
                        side: BorderSide(color: context.colors.line),
                        minimumSize: const Size(44, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.tune, size: 22),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (context.isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        spentCard,
                        const SizedBox(height: 16),
                        timelineCard,
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _TodayWalletsCard(
                          snapshot: snap,
                          hideAmounts: hideAmounts,
                        ),
                        const SizedBox(height: 16),
                        _TodayTipCard(
                          todayOut: todayOut,
                          budget: budget,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              spentCard,
              const SizedBox(height: 16),
              timelineCard,
            ],
          ],
        );
      },
    );
  }
}

class _TodayWalletsCard extends StatelessWidget {
  const _TodayWalletsCard({
    required this.snapshot,
    required this.hideAmounts,
  });

  final MoneySnapshot snapshot;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.wallets,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => WalletsScreen.open(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 30),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l.manageAction),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (snapshot.wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada dompet',
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
            ),
          for (final w in snapshot.wallets) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.isDark ? c.subtle : const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        w.type == 'cash'
                            ? Icons.payments_outlined
                            : (w.type == 'bank'
                                ? Icons.account_balance_outlined
                                : Icons.phone_android_outlined),
                        size: 18,
                        color: c.onPrimarySoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          w.type == 'cash'
                              ? 'Tunai'
                              : (w.type == 'bank' ? 'Rekening' : 'E-Wallet'),
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rupiah(snapshot.balanceOf(w.id), hide: hideAmounts),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayTipCard extends StatelessWidget {
  const _TodayTipCard({
    required this.todayOut,
    required this.budget,
  });

  final int todayOut;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = budget > 0 && todayOut > (budget ~/ 30)
        ? 'Pengeluaran hari ini sedikit di atas rata-rata harian. Tetap pantau catatanmu ya!'
        : 'Pengeluaran hari ini masih terkendali dan rapi. Semangat mencatat!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Mascot(MascotPose.senang, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Hari Ini',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.onPrimarySoft,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
