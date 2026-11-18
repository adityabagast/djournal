import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../domain/money_snapshot.dart';
import '../domain/money_calendar.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import 'money_widgets.dart';
import '../../../core/widgets/mascot.dart';
import '../../search/presentation/search_screen.dart';
import 'money_calendar_card.dart';
import 'tx_form_screen.dart';
import 'wallet_form_sheet.dart';
import 'wallets_screen.dart';
import '../../../core/tokens.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  /// null = semua, 'expense', 'income', 'transfer'
  String? _filter;

  /// Bulan kalender yang dibuka (tanggal 1); null = bulan ini.
  DateTime? _month;

  /// Tanggal kalender yang dipilih ("YYYY-MM-DD"); null = semua hari.
  String? _day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snapAsync = ref.watch(moneySnapshotProvider);
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final viewMonth = _month ?? thisMonth;
    final monthKey = toMonthKey(viewMonth);

    return snapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (snap) {
        final month = snap.inMonth(monthKey).toList();
        // Tanpa tanggal terpilih: bulan yang dibuka lalu hari-hari sebelumnya.
        final filtered = snap.transactions
            .where(
              (tx) =>
                  (_filter == null || tx.type == _filter) &&
                  (_day != null
                      ? tx.localDate == _day
                      : tx.localDate.substring(0, 7).compareTo(monthKey) <= 0),
            )
            .toList();
        final dayIsEmpty = _day != null && snap.onDate(_day!).isEmpty;
        // Transaksi terurut terbaru dulu, jadi yang terakhir = paling lama.
        final firstMonth = snap.transactions.isEmpty
            ? monthKey
            : snap.transactions.last.localDate.substring(0, 7);

        final calendar = MoneyCalendarCard(
          month: viewMonth,
          totals: dailyTotals(snap, monthKey),
          selectedDate: _day,
          hideAmounts: hideAmounts,
          canGoPrev: monthKey.compareTo(firstMonth) > 0,
          canGoNext: viewMonth.isBefore(thisMonth),
          onPrev: () => setState(() {
            _month = DateTime(viewMonth.year, viewMonth.month - 1);
            _day = null;
          }),
          onNext: () => setState(() {
            _month = DateTime(viewMonth.year, viewMonth.month + 1);
            _day = null;
          }),
          onPick: (d) => setState(() => _day = d),
        );
        final groups = <String, List<MoneyTx>>{};
        for (final tx in filtered) {
          groups.putIfAbsent(tx.localDate, () => []).add(tx);
        }

        final header = ScreenHeader(
          overline: DateFormat('MMMM y', context.localeTag).format(viewMonth),
          title: l.navMoney,
          trailing: const SearchButton(),
        );

        final balanceCard = _BalanceCard(
          total: snap.totalBalance,
          monthIn: MoneySnapshot.sumOf(month, 'income'),
          monthOut: MoneySnapshot.sumOf(month, 'expense'),
          hideAmounts: hideAmounts,
          onToggleHide: () => ref
              .read(settingsRepositoryProvider)
              .set('hide_amounts', (!hideAmounts).toString()),
        );

        final walletsHeader = Row(
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
                padding: const EdgeInsets.only(left: AppSpace.sm, right: 0),
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
        );

        final filterChips = SingleChildScrollView(
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
        );

        final txListWidgets = [
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
              message: dayIsEmpty ? l.calDayEmpty : l.mascotFilterEmptyBody,
              size: 140,
              action: dayIsEmpty
                  ? FilledButton.tonal(
                      onPressed: () => TxFormScreen.open(
                        context,
                        initialDate: _recordAt(_day!),
                      ),
                      child: Text('+ ${l.calRecord}'),
                    )
                  : null,
            ),
          for (final entry in groups.entries) ...[
            _DayHeader(
              label: dayLabel(context, entry.key),
              outTotal: MoneySnapshot.sumOf(entry.value, 'expense'),
              hideAmounts: hideAmounts,
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.xs,
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
            const SizedBox(height: AppSpace.lg),
          ],
        ];

        if (context.isWide) {
          return ListView(
            padding: context.screenPadding,
            children: [
              header,
              const SizedBox(height: AppSpace.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Saldo & Dompet
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        balanceCard,
                        const SizedBox(height: AppSpace.lg),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpace.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              walletsHeader,
                              const SizedBox(height: AppSpace.md),
                              for (final w in snap.wallets) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: AppSpace.sm),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.md,
                                    vertical: AppSpace.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.isDark
                                        ? context.colors.subtle
                                        : const Color(0xFFF7FAF8),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: context.colors.line,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => WalletFormSheet.open(
                                      context,
                                      existing: w,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: context.colors.primarySoft,
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              w.type == 'cash'
                                                  ? Icons.payments_outlined
                                                  : (w.type == 'bank'
                                                      ? Icons
                                                          .account_balance_outlined
                                                      : Icons
                                                          .phone_android_outlined),
                                              size: 18,
                                              color:
                                                  context.colors.onPrimarySoft,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpace.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                    : (w.type == 'bank'
                                                        ? 'Rekening'
                                                        : 'E-Wallet'),
                                                style: TextStyle(
                                                  fontSize: AppFontSize.caption,
                                                  color: context.colors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          rupiah(
                                            snap.balanceOf(w.id),
                                            hide: hideAmounts,
                                          ),
                                          style: const TextStyle(
                                            fontSize: AppFontSize.body,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.lg),
                  // Right Column: Filter & Transaksi
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        calendar,
                        const SizedBox(height: AppSpace.lg),
                        filterChips,
                        const SizedBox(height: AppSpace.lg),
                        ...txListWidgets,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return ListView(
          padding: context.screenPadding,
          children: [
            header,
            const SizedBox(height: AppSpace.lg),
            balanceCard,
            const SizedBox(height: AppSpace.lg),
            walletsHeader,
            const SizedBox(height: AppSpace.xs),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, w) in snap.wallets.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.md),
                    _WalletCard(
                      name: w.name,
                      balance: snap.balanceOf(w.id),
                      hideAmounts: hideAmounts,
                      onTap: () => WalletFormSheet.open(context, existing: w),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            calendar,
            const SizedBox(height: AppSpace.lg),
            filterChips,
            const SizedBox(height: AppSpace.lg),
            ...txListWidgets,
          ],
        );
      },
    );
  }

  /// Tanggal [localDate] dengan jam sekarang, untuk catat dari kalender.
  DateTime _recordAt(String localDate) {
    final d = parseLocalDate(localDate);
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day, now.hour, now.minute);
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.monthIn,
    required this.monthOut,
    required this.hideAmounts,
    required this.onToggleHide,
  });

  final int total;
  final int monthIn;
  final int monthOut;
  final bool hideAmounts;
  final VoidCallback onToggleHide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    Widget stat(String label, int value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: context.colors.onHero.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
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
                rupiah(value, hide: hideAmounts),
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
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: context.colors.hero,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.totalBalance,
                style: t.bodySmall?.copyWith(color: context.colors.onHeroMuted),
              ),
              const SizedBox(width: AppSpace.sm),
              InkWell(
                onTap: onToggleHide,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xxs),
                  child: Icon(
                    hideAmounts
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: context.colors.onHeroMuted,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              signedRupiah(total, hide: hideAmounts),
              style: t.headlineMedium?.copyWith(
                color: context.colors.onHero,
                fontWeight: FontWeight.w700,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              stat(l.income, monthIn),
              const SizedBox(width: AppSpace.md),
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
    required this.hideAmounts,
    required this.onTap,
  });

  final String name;
  final int balance;
  final bool hideAmounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: context.colors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
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
                  fontSize: AppFontSize.body,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  signedRupiah(balance, hide: hideAmounts),
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
        fontSize: AppFontSize.body,
        fontWeight: FontWeight.w600,
        color: selected ? context.colors.onPrimary : context.colors.ink,
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.outTotal,
    required this.hideAmounts,
  });

  final String label;
  final int outTotal;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.colors.muted, fontSize: AppFontSize.body);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (outTotal > 0)
            Text(
              '−${rupiah(outTotal, hide: hideAmounts)}',
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
