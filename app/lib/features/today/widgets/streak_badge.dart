import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../domain/models/streak_info.dart';
import '../../../providers.dart';
import '../../../ui/mascot.dart';

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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: flameBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: flameColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔥',
              style: TextStyle(
                fontSize: 15,
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
            const SizedBox(width: 4),
            Text(
              '${streak.currentStreak} Hari',
              style: TextStyle(
                fontSize: 12,
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

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Mascot(
                    streak.isTodayActive ? MascotPose.senang : MascotPose.halo,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 18)),
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
              const SizedBox(height: 20),
              Text(
                'Rutinitas Nyawtat Hari Ini',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.subtle,
                  borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDone ? flameColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDone ? flameColor : context.colors.line,
                width: 1.5,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
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
