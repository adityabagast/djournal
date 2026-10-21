import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../domain/models/streak_info.dart';
import 'journal_providers.dart';
import 'money_providers.dart';

final streakProvider = Provider<StreakInfo>((ref) {
  final entries = ref.watch(journalEntriesProvider).value ?? const [];
  final txs = ref.watch(moneySnapshotProvider).value?.transactions ??
      ref.watch(transactionsProvider).value ??
      const [];
  final now = DateTime.now();

  final activeDates = <String>{};
  for (final e in entries) {
    activeDates.add(e.entryDate);
  }
  for (final t in txs) {
    activeDates.add(t.localDate);
  }

  return StreakInfo.calculate(activeDates: activeDates, now: now);
});

class DailyRoutineState {
  const DailyRoutineState({
    required this.hasJournalToday,
    required this.hasTransactionToday,
    required this.hasSavingsToday,
  });

  final bool hasJournalToday;
  final bool hasTransactionToday;
  final bool hasSavingsToday;

  bool get isAnyDone => hasJournalToday || hasTransactionToday || hasSavingsToday;
}

final dailyRoutineProvider = Provider<DailyRoutineState>((ref) {
  final entries = ref.watch(journalEntriesProvider).value ?? const [];
  final txs = ref.watch(moneySnapshotProvider).value?.transactions ??
      ref.watch(transactionsProvider).value ??
      const [];
  final today = toLocalDate(DateTime.now());

  final hasJournal = entries.any((e) => e.entryDate == today);
  final hasTx = txs.any((t) => t.localDate == today && t.type != 'transfer');
  final hasSavings = txs.any((t) =>
      t.localDate == today &&
      (t.type == 'transfer' || (t.note != null && t.note!.contains('Wishlist'))));

  return DailyRoutineState(
    hasJournalToday: hasJournal,
    hasTransactionToday: hasTx,
    hasSavingsToday: hasSavings,
  );
});
