import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../journal/data/journal_repository.dart';
import '../../money/domain/money_snapshot.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../money/presentation/money_widgets.dart';
import '../../../core/widgets/mascot.dart';
import '../../games/presentation/games_hub_screen.dart';
import '../../plan/presentation/plan_section.dart';
import '../../journal/presentation/entry_form_screen.dart';
import '../../journal/presentation/entry_rows.dart';
import '../../money/presentation/tx_form_screen.dart';
import '../../money/presentation/wallets_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../update/presentation/update_card.dart';
import '../../reminders/presentation/upcoming_events_card.dart';
import 'widgets/bills_card.dart';
import 'widgets/budget_warning_banner.dart';
import 'widgets/global_budget_card.dart';
import 'widgets/streak_badge.dart';
import 'widgets/wishlist_card.dart';
import '../../../core/tokens.dart';

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
                            Flexible(
                              child: Text(
                                l.todaySpent,
                                style: t.bodySmall?.copyWith(
                                  color: context.colors.muted,
                                  fontSize: AppFontSize.body,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            InkWell(
                              onTap: () => ref
                                  .read(settingsRepositoryProvider)
                                  .set(
                                    'hide_amounts',
                                    (!hideAmounts).toString(),
                                  ),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.xxs),
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
                              fontSize: AppFontSize.body,
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
                const SizedBox(height: AppSpace.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: LinearProgressIndicator(
                    value: (monthOut / budget).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: context.colors.track,
                    color: monthOut > budget
                        ? context.colors.expense
                        : context.colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l.budgetUsage(
                    DateFormat('MMMM', context.localeTag).format(now),
                    (monthOut * 100 / budget).round(),
                    rupiah(
                      (budget - monthOut).clamp(0, budget),
                      hide: hideAmounts,
                    ),
                  ),
                  style: t.bodySmall?.copyWith(
                    color: context.colors.muted,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ],
            ],
          ),
        );

        final timelineCard = AppCard(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
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
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                      shape: const StadiumBorder(),
                      textStyle: buttonTextStyle(
                        context,
                        const TextStyle(
                          fontSize: AppFontSize.body,
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
                  const StreakBadge(),
                  const SearchButton(),
                  if (!context.isWide)
                    IconButton.outlined(
                      tooltip: l.settings,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        side: BorderSide.none,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.tune, size: 22),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            const UpdateCard(),
            _GreetingCard(now: now, count: timeline.length),
            const SizedBox(height: AppSpace.lg),
            PlanSection(now: now),
            const SizedBox(height: AppSpace.lg),
            const RestCard(),
            const SizedBox(height: AppSpace.lg),
            const UpcomingEventsCard(),
            BudgetWarningBanner(snapshot: snap, now: now),
            if (context.isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        spentCard,
                        const SizedBox(height: AppSpace.lg),
                        GlobalBudgetCard(
                          snapshot: snap,
                          now: now,
                          hideAmounts: hideAmounts,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        timelineCard,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        BillsCard(now: now),
                        const SizedBox(height: AppSpace.lg),
                        const WishlistCard(),
                        const SizedBox(height: AppSpace.lg),
                        _TodayWalletsCard(
                          snapshot: snap,
                          hideAmounts: hideAmounts,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        _TodayTipCard(todayOut: todayOut, budget: budget),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              spentCard,
              const SizedBox(height: AppSpace.lg),
              GlobalBudgetCard(
                snapshot: snap,
                now: now,
                hideAmounts: hideAmounts,
              ),
              const SizedBox(height: AppSpace.lg),
              timelineCard,
              const SizedBox(height: AppSpace.lg),
              BillsCard(now: now),
              const SizedBox(height: AppSpace.lg),
              const WishlistCard(),
            ],
          ],
        );
      },
    );
  }
}

/// Sapaan maskot di atas Hari Ini: salam sesuai jam dan jumlah catatan.
class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.now, required this.count});

  final DateTime now;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final greeting = switch (now.hour) {
      < 11 => l.greetingMorning,
      < 15 => l.greetingNoon,
      < 18 => l.greetingAfternoon,
      _ => l.greetingEvening,
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.lg, AppSpace.lg, 0),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Mascot(count == 0 ? MascotPose.tidur : MascotPose.halo, size: 86),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: AppFontSize.heading,
                      fontWeight: FontWeight.w700,
                      color: c.onPrimarySoft,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    count == 0 ? l.greetingEmpty : l.greetingCount(count),
                    style: TextStyle(fontSize: AppFontSize.body, color: c.onPrimarySoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayWalletsCard extends StatelessWidget {
  const _TodayWalletsCard({required this.snapshot, required this.hideAmounts});

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs,
                  ),
                  minimumSize: const Size(0, 30),
                  textStyle: const TextStyle(
                    fontSize: AppFontSize.meta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l.manageAction),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (snapshot.wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Text(
                'Belum ada dompet',
                style: TextStyle(color: c.muted, fontSize: AppFontSize.body),
              ),
            ),
          for (final w in snapshot.wallets) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
              decoration: BoxDecoration(
                color: c.isDark ? c.subtle : const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.name,
                          style: const TextStyle(
                            fontSize: AppFontSize.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          w.type == 'cash'
                              ? 'Tunai'
                              : (w.type == 'bank' ? 'Rekening' : 'E-Wallet'),
                          style: TextStyle(fontSize: AppFontSize.caption, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rupiah(snapshot.balanceOf(w.id), hide: hideAmounts),
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
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
  const _TodayTipCard({required this.todayOut, required this.budget});

  final int todayOut;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = budget > 0 && todayOut > (budget ~/ 30)
        ? 'Pengeluaran hari ini sedikit di atas rata-rata harian. Tetap pantau catatanmu ya!'
        : 'Pengeluaran hari ini masih terkendali dan rapi. Semangat mencatat!';

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Mascot(MascotPose.senang, size: 44),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Hari Ini',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: c.onPrimarySoft,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  message,
                  style: TextStyle(fontSize: AppFontSize.meta, color: c.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
