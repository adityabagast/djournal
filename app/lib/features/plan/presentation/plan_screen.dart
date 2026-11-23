import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../providers.dart';
import '../domain/daily_plan.dart';
import 'plan_widgets.dart';

/// Rencana harian: daftar hari ini dan besok, plus progres 7 hari.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key, this.tomorrow = false, this.now});

  final bool tomorrow;

  /// Untuk tes; bawaan jam sekarang.
  final DateTime? now;

  static Future<void> open(BuildContext context, {bool tomorrow = false}) =>
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PlanScreen(tomorrow: tomorrow)));

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  late bool _tomorrow = widget.tomorrow;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final all = ref.watch(plansProvider).value ?? const <DailyPlan>[];
    final today = toLocalDate(widget.now ?? DateTime.now());
    final date = _tomorrow ? nextDay(today) : today;
    final plans = plansOn(all, date);
    final progress = PlanProgress.of(plans);

    return Scaffold(
      appBar: AppBar(
        title: FitText(
          l.planTitle,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.sm,
          AppSpace.xl,
          AppSpace.xxxl,
        ),
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: FitText(l.today)),
              ButtonSegment(value: true, label: FitText(l.planTomorrow)),
            ],
            selected: {_tomorrow},
            onSelectionChanged: (s) => setState(() => _tomorrow = s.first),
          ),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.sm,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, d MMMM',
                        context.localeTag,
                      ).format(parseLocalDate(date)),
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _tomorrow
                          ? l.planCount(plans.length)
                          : l.planDoneCount(progress.done, progress.total),
                      style: t.bodySmall?.copyWith(color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                if (plans.isEmpty)
                  Text(
                    _tomorrow ? l.planEmptyTomorrow : l.planEmptyToday,
                    style: t.bodySmall?.copyWith(color: c.muted, height: 1.5),
                  ),
                for (final (i, p) in plans.indexed)
                  PlanRow(
                    key: ValueKey(p.id),
                    plan: p,
                    checkable: !_tomorrow,
                    showDivider: i < plans.length - 1,
                    onMenu: () =>
                        PlanEditSheet.open(context, plan: p, today: today),
                  ),
                const SizedBox(height: AppSpace.md),
                PlanAddField(
                  key: ValueKey(date),
                  date: date,
                  label: _tomorrow ? l.planAddTomorrow : l.planAddToday,
                  hint: _tomorrow ? l.planHint : l.planAddToday,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _WeekCard(plans: all, today: today),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.plans, required this.today});

  final List<DailyPlan> plans;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final days = [
      for (final d in lastSevenDays(today))
        (d, PlanProgress.of(plansOn(plans, d))),
    ];
    final dayName = DateFormat('EEE', context.localeTag);
    const barHeight = 64.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.sm,
            children: [
              Text(
                l.planWeek,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                l.planWeekDone(days.where((d) => d.$2.allDone).length),
                style: t.bodySmall?.copyWith(color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              for (final (date, p) in days)
                Expanded(
                  child: Semantics(
                    label:
                        '${dayName.format(parseLocalDate(date))}, '
                        '${l.planPercent(p.percent)}',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            width: 26,
                            height: barHeight,
                            color: c.track,
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: AppMotion.short,
                              height: barHeight * p.percent / 100,
                              color: c.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.xxs,
                          ),
                          child: FitText(
                            dayName.format(parseLocalDate(date)),
                            alignment: Alignment.center,
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: date == today
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: date == today ? c.ink : c.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
