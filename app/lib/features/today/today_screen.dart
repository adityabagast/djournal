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

        // Timeline: entri jurnal dan transaksi hari ini, urut jam naik.
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
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        final monthOut = MoneySnapshot.sumOf(
          snap.inMonth(toMonthKey(now)),
          'expense',
        );
        final budget = snap.totalBudget(toMonthKey(now));

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 124),
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
            AppCard(
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
            ),
            const SizedBox(height: 16),
            AppCard(
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
            ),
          ],
        );
      },
    );
  }
}
