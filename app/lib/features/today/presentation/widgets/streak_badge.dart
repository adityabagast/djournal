import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../domain/streak_info.dart';
import '../../../../providers.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/tokens.dart';
import '../../../../core/widgets/app_sheet.dart';

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final routine = ref.watch(dailyRoutineProvider);
    final flameColor = const Color(0xFFEA580C);
    final flameBg = context.colors.isDark ? const Color(0xFF382012) : const Color(0xFFFFF7ED);

    return InkWell(
      onTap: () => _showStreakSheet(context, streak, routine),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: flameBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: flameColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔥',
              style: TextStyle(
                fontSize: AppFontSize.title,
                shadows: streak.isTodayActive
                    ? [
                        Shadow(
                          color: flameColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              '${streak.currentStreak} Hari',
              style: TextStyle(
                fontSize: AppFontSize.meta,
                fontWeight: FontWeight.w700,
                color: flameColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showStreakSheet(
    BuildContext context,
    StreakInfo streak,
    DailyRoutineState routine,
  ) {
    final t = Theme.of(context).textTheme;
    final flameColor = const Color(0xFFEA580C);

    showAppSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Mascot(
                    streak.isTodayActive ? MascotPose.senang : MascotPose.halo,
                    size: 48,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: AppFontSize.heading)),
                            Text(
                              '${streak.currentStreak} Hari Berturut-turut',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: flameColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          streak.isTodayActive
                              ? 'Api streak aktif hari ini! Pertahankan besok!'
                              : 'Lakukan minimal satu rutinitas untuk menyalakan api hari ini.',
                          style: t.bodySmall?.copyWith(color: context.colors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Rutinitas Nyawtat Hari Ini',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.md),
              _RoutineItem(
                title: 'Tulis minimal 1 jurnal',
                isDone: routine.hasJournalToday,
              ),
              _RoutineItem(
                title: 'Catat pemasukan / pengeluaran',
                isDone: routine.hasTransactionToday,
              ),
              _RoutineItem(
                title: 'Sisihkan tabungan wishlist',
                isDone: routine.hasSavingsToday,
              ),
              const SizedBox(height: AppSpace.lg),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: context.colors.subtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rekor Streak Terpanjang:',
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                    Text(
                      '${streak.longestStreak} Hari',
                      style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoutineItem extends StatelessWidget {
  const _RoutineItem({required this.title, required this.isDone});

  final String title;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final flameColor = const Color(0xFFEA580C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDone ? flameColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isDone ? flameColor : context.colors.line,
                width: 1.5,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppFontSize.body,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? context.colors.muted : context.colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
