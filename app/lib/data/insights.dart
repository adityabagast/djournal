import 'db/app_database.dart';
import 'journal_repository.dart';
import 'money_snapshot.dart';

/// Rata-rata pengeluaran harian di hari ber-mood baik (≥ 4) dan
/// kurang (≤ 3), mengikuti desain. null = belum ada hari seperti itu.
({int? good, int? low}) moodSpending(
  List<JournalEntry> entries,
  MoneySnapshot money,
) {
  final good = <int>[];
  final low = <int>[];
  for (final date in {for (final e in entries) e.entryDate}) {
    final mood = dayMood(entries, date);
    if (mood == null) continue;
    final spent = MoneySnapshot.sumOf(money.onDate(date), 'expense');
    (mood >= 4 ? good : low).add(spent);
  }
  int? avg(List<int> xs) =>
      xs.isEmpty ? null : (xs.reduce((a, b) => a + b) / xs.length).round();
  return (good: avg(good), low: avg(low));
}
