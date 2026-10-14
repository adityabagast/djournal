import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../ui/common.dart';

class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.spent,
    required this.percentage,
  });

  final Category category;
  final int spent;
  final double percentage; // 0.0 - 100.0
}

/// Donut chart interaktif distribusi pengeluaran per kategori.
class ExpenseDonutChart extends StatefulWidget {
  const ExpenseDonutChart({
    super.key,
    required this.items,
    required this.totalSpent,
    required this.hideAmounts,
    this.selectedCategoryId,
    this.onSelectCategory,
  });

  final List<CategorySpend> items;
  final int totalSpent;
  final bool hideAmounts;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onSelectCategory;

  @override
  State<ExpenseDonutChart> createState() => _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final items = widget.items;
    final total = widget.totalSpent;
    final selectedId = widget.selectedCategoryId;

    final selected = items.where((i) => i.category.id == selectedId).firstOrNull;

    // Tampilkan 5 teratas secara default, sisanya bisa di-expand.
    final displayItems = _showAll || items.length <= 5 ? items : items.take(5).toList();

    return Column(
      children: [
        // Donut Chart dengan Center Text
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, child) {
                    return GestureDetector(
                      onTapUp: (details) {
                        _handleTap(details.localPosition, const Size(200, 200));
                      },
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _DonutPainter(
                          items: items,
                          selectedId: selectedId,
                          progress: progress,
                          themeColors: context.colors,
                        ),
                      ),
                    );
                  },
                ),
                // Center info display
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected != null) ...[
                        Text(
                          categoryLabel(l, selected.category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(
                            color: context.colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rupiah(selected.spent, hide: widget.hideAmounts),
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.soft(hexColor(selected.category.color)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${selected.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.colors.fg(hexColor(selected.category.color)),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          l.totalExpense,
                          style: t.bodySmall?.copyWith(
                            color: context.colors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rupiah(total, hide: widget.hideAmounts),
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.categoryCount(items.length),
                          style: t.bodySmall?.copyWith(
                            color: context.colors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // List item kategori terurut
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = displayItems[index];
            final isSelected = item.category.id == selectedId;
            final catColor = hexColor(item.category.color);

            return InkWell(
              onTap: () {
                final next = isSelected ? null : item.category.id;
                widget.onSelectCategory?.call(next);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.soft(catColor)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.fg(catColor)
                        : context.colors.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CategoryBadge(category: item.category, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  categoryLabel(l, item.category),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.fg(catColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (item.percentage / 100.0).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: context.colors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.fg(catColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      rupiah(item.spent, hide: widget.hideAmounts),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected ? context.colors.ink : context.colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Tombol expand/collapse jika lebih dari 5 kategori
        if (items.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(
                _showAll ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _showAll
                    ? l.chartShowLess
                    : l.chartAllCategories(items.length),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleTap(Offset pos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Donut radius checks: diameter 200 => radius 100. Hole radius ~ 58
    if (distance < 50 || distance > 105) {
      widget.onSelectCategory?.call(null);
      return;
    }

    // Hitung sudut tap (0 sampai 2*pi, mulai dari jam 12 / -pi/2)
    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2) % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;

    final items = widget.items;
    final gap = items.length > 1 ? 0.04 : 0.0;
    final available = 2 * math.pi - (gap * items.length);

    var current = 0.0;
    for (final item in items) {
      final sweep = (item.percentage / 100.0) * available;
      if (angle >= current && angle <= current + sweep) {
        final next = widget.selectedCategoryId == item.category.id ? null : item.category.id;
        widget.onSelectCategory?.call(next);
        return;
      }
      current += sweep + gap;
    }

    widget.onSelectCategory?.call(null);
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.items,
    required this.selectedId,
    required this.progress,
    required this.themeColors,
  });

  final List<CategorySpend> items;
  final String? selectedId;
  final double progress;
  final AppPalette themeColors;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 24.0;

    final gap = items.length > 1 ? 0.04 : 0.0;
    final totalRadians = 2 * math.pi - (gap * items.length);

    // Mulai dari atas (jam 12 = -pi / 2)
    var startAngle = -math.pi / 2;

    for (final item in items) {
      final isSelected = item.category.id == selectedId;
      final sweepAngle = (item.percentage / 100.0) * totalRadians * progress;
      final rawColor = hexColor(item.category.color);
      final catColor = themeColors.fg(rawColor);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = selectedId == null || isSelected
            ? catColor
            : catColor.withValues(alpha: 0.3);

      final currentRadius = isSelected ? radius + 2 : radius;
      final rect = Rect.fromCircle(center: center, radius: currentRadius);

      if (sweepAngle > 0.001) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }

      startAngle += sweepAngle + (gap * progress);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId ||
        oldDelegate.progress != progress ||
        oldDelegate.items != items;
  }
}

/// Bar chart tren pengeluaran mingguan dalam satu bulan.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.monthTransactions,
    required this.month,
    required this.hideAmounts,
  });

  final List<MoneyTx> monthTransactions;
  final DateTime month;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    // Hitung jumlah hari dalam bulan ini
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Bagi bulan ke dalam 4 atau 5 minggu (7 hari per minggu)
    final weekRanges = <(int start, int end)>[
      (1, 7),
      (8, 14),
      (15, 21),
      (22, 28),
      if (daysInMonth > 28) (29, daysInMonth),
    ];

    final weekExpenses = List<int>.filled(weekRanges.length, 0);

    for (final tx in monthTransactions) {
      if (tx.type != 'expense') continue;
      final day = parseLocalDate(tx.localDate).day;
      for (var i = 0; i < weekRanges.length; i++) {
        final (start, end) = weekRanges[i];
        if (day >= start && day <= end) {
          weekExpenses[i] += tx.amount;
          break;
        }
      }
    }

    final maxSpent = weekExpenses.fold<int>(0, math.max);
    final totalSpent = weekExpenses.fold<int>(0, (sum, val) => sum + val);
    final avgWeekly = weekRanges.isNotEmpty ? (totalSpent / weekRanges.length).round() : 0;

    var highestWeekIdx = 0;
    for (var i = 1; i < weekExpenses.length; i++) {
      if (weekExpenses[i] > weekExpenses[highestWeekIdx]) {
        highestWeekIdx = i;
      }
    }

    return Column(
      children: [
        // Bar diagram container
        Container(
          height: 190,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < weekRanges.length; i++) ...[
                Expanded(
                  child: _WeekBar(
                    weekNumber: i + 1,
                    range: '${weekRanges[i].$1}–${weekRanges[i].$2}',
                    spent: weekExpenses[i],
                    maxSpent: maxSpent,
                    isHighest: weekExpenses[i] == maxSpent && maxSpent > 0,
                    hideAmounts: hideAmounts,
                  ),
                ),
                if (i < weekRanges.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ringkasan statistik mingguan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.chartAvgWeekly,
                      style: t.bodySmall?.copyWith(color: context.colors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rupiah(avgWeekly, hide: hideAmounts),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: context.colors.divider),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.chartHighestWeek(highestWeekIdx + 1),
                      style: t.bodySmall?.copyWith(color: context.colors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rupiah(maxSpent, hide: hideAmounts),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: maxSpent > 0 ? context.colors.expense : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.weekNumber,
    required this.range,
    required this.spent,
    required this.maxSpent,
    required this.isHighest,
    required this.hideAmounts,
  });

  final int weekNumber;
  final String range;
  final int spent;
  final int maxSpent;
  final bool isHighest;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const maxBarHeight = 110.0;
    final ratio = maxSpent > 0 ? (spent / maxSpent).clamp(0.0, 1.0) : 0.0;
    final barHeight = (ratio * maxBarHeight).clamp(spent > 0 ? 6.0 : 0.0, maxBarHeight);

    final barColor = isHighest
        ? context.colors.expense
        : context.colors.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Label nominal di atas bar
        SizedBox(
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              spent == 0 ? '−' : (hideAmounts ? '••••' : rupiah(spent)),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isHighest ? FontWeight.w700 : FontWeight.w500,
                color: isHighest ? context.colors.expense : context.colors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Track bar
        Container(
          width: double.infinity,
          height: maxBarHeight,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: context.colors.isDark
                ? const Color(0xFF1F2421)
                : const Color(0xFFEEF3F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: barHeight),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (context, height, _) {
              return Container(
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Label minggu & rentang tanggal
        Text(
          'M$weekNumber',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isHighest ? context.colors.expense : context.colors.ink,
          ),
        ),
        Text(
          range,
          style: t.bodySmall?.copyWith(
            color: context.colors.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
