import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../domain/money_calendar.dart';
import '../../../core/widgets/common.dart';
import '../../../core/tokens.dart';

/// Kalender bulanan di layar Keuangan: tiap tanggal menampilkan total keluar
/// dan masuk secara ringkas. Ketuk tanggal untuk memfilter daftar transaksi.
class MoneyCalendarCard extends StatelessWidget {
  const MoneyCalendarCard({
    super.key,
    required this.month,
    required this.totals,
    required this.selectedDate,
    required this.hideAmounts,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  /// Tanggal 1 bulan yang ditampilkan.
  final DateTime month;
  final Map<String, DayTotal> totals;

  /// "YYYY-MM-DD" yang dipilih, atau null.
  final String? selectedDate;
  final bool hideAmounts;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// Dipanggil dengan tanggal yang diketuk; null = batal pilih.
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final tag = context.localeTag;
    final today = toLocalDate(DateTime.now());
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final blanks = month.weekday - 1; // Minggu dimulai hari Senin.
    // 5 Jan 2026 = Senin; dipakai hanya untuk nama hari.
    final dow = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(tag).format(DateTime(2026, 1, 5 + i)),
    ];
    final sel = selectedDate == null ? null : totals[selectedDate];

    final rows = <Widget>[];
    for (var start = -blanks; start < daysInMonth; start += 7) {
      rows.add(
        Row(
          children: [
            for (var i = start; i < start + 7; i++)
              Expanded(
                child: i < 0 || i >= daysInMonth
                    ? const SizedBox()
                    : _cell(context, i + 1, today),
              ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: canGoPrev ? onPrev : null,
                tooltip: l.calPrevMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM y', tag).format(month),
                  textAlign: TextAlign.center,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: canGoNext ? onNext : null,
                tooltip: l.calNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in dow)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppFontSize.caption, color: c.muted),
                    ),
                  ),
                ),
            ],
          ),
          ...rows,
          const SizedBox(height: AppSpace.sm),
          if (selectedDate == null)
            Text(
              l.calHint,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: c.muted),
            )
          else ...[
            Row(
              children: [
                _sum(context, l.calOut, sel?.expense ?? 0, c.expense),
                const SizedBox(width: AppSpace.sm),
                _sum(context, l.calIn, sel?.income ?? 0, c.income),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () => onPick(null),
                child: Text(l.calShowAllDays),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sum(BuildContext context, String label, int value, Color color) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: c.subtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: AppFontSize.caption, color: c.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rupiah(value, hide: hideAmounts),
                style: TextStyle(
                  fontSize: AppFontSize.bodyLg,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int day, String today) {
    final l = context.l10n;
    final c = context.colors;
    final date = toLocalDate(DateTime(month.year, month.month, day));
    final total = totals[date];
    final isToday = date == today;
    final isFuture = date.compareTo(today) > 0;
    final selected = date == selectedDate;
    final out = total?.expense ?? 0;
    final inc = total?.income ?? 0;

    Widget amount(String text, Color color) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: AppFontSize.caption,
          height: 1.25,
          fontWeight: FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    final dayName = DateFormat(
      'EEEE, d MMM',
      context.localeTag,
    ).format(DateTime(month.year, month.month, day));
    final label = isFuture
        ? '$dayName, ${l.calNoData}'
        : '$dayName, ${l.calOut} ${rupiah(out, hide: hideAmounts)}, '
              '${l.calIn} ${rupiah(inc, hide: hideAmounts)}';

    return Semantics(
      button: !isFuture,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: ValueKey('cal-$date'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: isFuture ? null : () => onPick(selected ? null : date),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs, horizontal: 1),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? c.primary : null,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: isFuture
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: isToday
                            ? c.onPrimary
                            : (isFuture ? c.muted : c.ink),
                      ),
                    ),
                  ),
                  if (out > 0)
                    amount(
                      hideAmounts ? '•••' : '-${shortAmount(out)}',
                      c.expense,
                    ),
                  if (inc > 0)
                    amount(
                      hideAmounts ? '•••' : '+${shortAmount(inc)}',
                      c.income,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
