import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../../providers.dart';
import '../domain/daily_plan.dart';
import 'plan_add_sheet.dart';
import 'plan_screen.dart';
import 'plan_widgets.dart';

/// Kartu rencana di Hari Ini: geser untuk berpindah antara hari ini dan
/// besok, satu tombol untuk membuat rencana.
class PlanSection extends ConsumerStatefulWidget {
  const PlanSection({super.key, required this.now});

  final DateTime now;

  /// Mulai jam ini pilihan awal di popup adalah besok.
  static const eveningHour = 17;

  @override
  ConsumerState<PlanSection> createState() => _PlanSectionState();
}

class _PlanSectionState extends ConsumerState<PlanSection> {
  static const _shown = 4;
  static const _swipeDistance = 48.0;
  static const _swipeVelocity = 300.0;

  bool _tomorrow = false;

  /// Geseran jari yang sedang berlangsung.
  double _drag = 0;

  void _show(bool tomorrow) => setState(() {
    _tomorrow = tomorrow;
    _drag = 0;
  });

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_drag < -_swipeDistance || v < -_swipeVelocity) {
      _show(true);
    } else if (_drag > _swipeDistance || v > _swipeVelocity) {
      _show(false);
    } else {
      setState(() => _drag = 0);
    }
  }

  Future<void> _add(String today) async {
    final day = await PlanAddSheet.open(
      context,
      today: today,
      tomorrow: _tomorrow || widget.now.hour >= PlanSection.eveningHour,
    );
    if (day != null && mounted) _show(day);
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final ignored = ref.watch(planIgnoredThroughProvider);
    // Tunggu data terbaca supaya kartu kosong tidak sempat berkedip.
    if (!plansAsync.hasValue || !ignored.hasValue) {
      return const SizedBox.shrink();
    }
    final plans = plansAsync.value!;
    final today = toLocalDate(widget.now);
    final todayPlans = plansOn(plans, today);
    final tomorrowPlans = plansOn(plans, nextDay(today));
    final left = leftovers(plans, today, ignoredThrough: ignored.value);

    if (todayPlans.isEmpty && tomorrowPlans.isEmpty && left.isEmpty) {
      return AppCard(child: _Empty(onAdd: () => _add(today)));
    }

    // Di tepi (tidak ada halaman lagi) geseran terasa lebih berat.
    final edge = _tomorrow ? _drag < 0 : _drag > 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) =>
                setState(() => _drag += d.primaryDelta ?? 0),
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: () => setState(() => _drag = 0),
            child: ClipRect(
              child: AnimatedSize(
                duration: AppMotion.page,
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.page,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  // Tinggi mengikuti halaman yang baru.
                  layoutBuilder: (current, previous) => Stack(
                    children: [
                      for (final p in previous)
                        Positioned(top: 0, left: 0, right: 0, child: p),
                      ?current,
                    ],
                  ),
                  transitionBuilder: (child, animation) {
                    final fromRight = child.key == const ValueKey(true);
                    return SlideTransition(
                      position: Tween(
                        begin: Offset(fromRight ? 1 : -1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: Transform.translate(
                    key: ValueKey(_tomorrow),
                    offset: Offset(edge ? _drag / 4 : _drag, 0),
                    child: _tomorrow
                        ? _TomorrowPage(
                            plans: tomorrowPlans,
                            date: nextDay(today),
                            shown: _shown,
                          )
                        : _TodayPage(
                            plans: todayPlans,
                            left: left,
                            today: today,
                            shown: _shown,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          _Footer(tomorrow: _tomorrow, onShow: _show, onAdd: () => _add(today)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Mascot(MascotPose.halo, size: 60),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.planCard,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l.planCardEmpty,
                    style: t.bodySmall?.copyWith(
                      color: context.colors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l.planCreate),
        ),
      ],
    );
  }
}

/// Titik penanda hari, petunjuk geser, dan tombol tambah.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.tomorrow,
    required this.onShow,
    required this.onAdd,
  });

  final bool tomorrow;
  final ValueChanged<bool> onShow;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;

    Widget dot(bool day, String label) {
      final on = tomorrow == day;
      return Semantics(
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: () => onShow(day),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              width: 32,
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: AppMotion.short,
                  width: on ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on ? c.primary : c.handle,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          dot(false, l.planSeeToday),
          dot(true, l.planSeeTomorrow),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: FitText(
              tomorrow ? l.planSwipeToday : l.planSwipeTomorrow,
              style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.add),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onAll,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        leading,
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onAll, child: Text(context.l10n.planAll)),
      ],
    );
  }
}

class _TodayPage extends StatelessWidget {
  const _TodayPage({
    required this.plans,
    required this.left,
    required this.today,
    required this.shown,
  });

  final List<DailyPlan> plans;
  final List<DailyPlan> left;
  final String today;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final progress = PlanProgress.of(plans);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageHeader(
          leading: _Ring(percent: progress.percent),
          title: l.planTodayTitle,
          subtitle: plans.isEmpty
              ? l.planNone
              : l.planSummary(progress.done, progress.total),
          onAll: () => PlanScreen.open(context),
        ),
        const SizedBox(height: AppSpace.sm),
        if (left.isNotEmpty) ...[
          _LeftoverBanner(plans: left, today: today),
          const SizedBox(height: AppSpace.sm),
        ],
        _PlanList(
          plans: plans,
          shown: shown,
          empty: l.planEmptyToday,
          onMore: () => PlanScreen.open(context),
        ),
        if (progress.allDone) ...[
          const SizedBox(height: AppSpace.sm),
          _Nyaw(pose: MascotPose.senang, text: l.planAllDone),
        ],
      ],
    );
  }
}

class _TomorrowPage extends StatelessWidget {
  const _TomorrowPage({
    required this.plans,
    required this.date,
    required this.shown,
  });

  final List<DailyPlan> plans;
  final String date;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final day = DateFormat(
      'EEEE, d MMM',
      context.localeTag,
    ).format(parseLocalDate(date));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageHeader(
          leading: Container(
            width: _Ring.size,
            height: _Ring.size,
            decoration: BoxDecoration(
              color: c.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 32,
              color: c.onPrimarySoft,
            ),
          ),
          title: l.planTomorrowTitle,
          subtitle: plans.isEmpty
              ? day
              : l.planTomorrowCount(plans.length, day),
          onAll: () => PlanScreen.open(context, tomorrow: true),
        ),
        const SizedBox(height: AppSpace.sm),
        _PlanList(
          plans: plans,
          shown: shown,
          checkable: false,
          empty: l.planTomorrowNone,
          onMore: () => PlanScreen.open(context, tomorrow: true),
        ),
      ],
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.shown,
    required this.empty,
    required this.onMore,
    this.checkable = true,
  });

  final List<DailyPlan> plans;
  final int shown;
  final String empty;
  final VoidCallback onMore;
  final bool checkable;

  @override
  Widget build(BuildContext context) {
    final rows = plans.take(shown).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Text(
              empty,
              style: TextStyle(
                fontSize: AppFontSize.meta,
                color: context.colors.muted,
              ),
            ),
          ),
        for (final (i, p) in rows.indexed)
          PlanRow(
            key: ValueKey(p.id),
            plan: p,
            checkable: checkable,
            showDivider: i < rows.length - 1,
          ),
        if (plans.length > shown)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onMore,
              child: Text(context.l10n.planMore(plans.length - shown)),
            ),
          ),
      ],
    );
  }
}

class _LeftoverBanner extends ConsumerWidget {
  const _LeftoverBanner({required this.plans, required this.today});

  final List<DailyPlan> plans;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.warnSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.planLeft(plans.length),
            style: TextStyle(fontWeight: FontWeight.w600, color: c.onWarnSoft),
          ),
          Text(
            plans.map((p) => p.title).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppFontSize.body,
              height: 1.5,
              color: c.onWarnSoft,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => ref
                    .read(settingsRepositoryProvider)
                    .set(planIgnoredKey, plans.last.planDate),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.onWarnSoft,
                  side: BorderSide(color: c.onWarnSoft),
                ),
                child: Text(l.planLeftKeep),
              ),
              FilledButton(
                onPressed: () => ref.read(planRepositoryProvider).move([
                  for (final p in plans) p.id,
                ], today),
                child: Text(l.planMoveToday),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.percent});

  final int percent;

  static const size = 76.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: context.l10n.planPercent(percent),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 6,
              strokeAlign: CircularProgressIndicator.strokeAlignInside,
              strokeCap: StrokeCap.round,
              backgroundColor: c.track,
              color: c.primary,
            ),
            // Jarak angka ke ring tetap lega, juga untuk "100%".
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: FitText(
                '$percent%',
                alignment: Alignment.center,
                style: const TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Nyaw extends StatelessWidget {
  const _Nyaw({required this.pose, required this.text});

  final MascotPose pose;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Mascot(pose, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppFontSize.body,
                height: 1.5,
                color: c.onPrimarySoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
