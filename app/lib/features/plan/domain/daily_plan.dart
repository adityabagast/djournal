import '../../../core/database/app_database.dart';
import '../../../core/format.dart';

/// Riwayat yang dibaca: cukup untuk progres 7 hari dan sisa rencana.
const planHistoryDays = 30;

const planTitleMax = 80;

/// Progres rencana di satu hari.
class PlanProgress {
  const PlanProgress(this.done, this.total);

  factory PlanProgress.of(Iterable<DailyPlan> plans) =>
      PlanProgress(plans.where((p) => p.doneAt != null).length, plans.length);

  final int done;
  final int total;

  int get percent => total == 0 ? 0 : (done * 100 / total).round();
  bool get allDone => total > 0 && done == total;
}

String _shift(String date, int days) {
  final d = parseLocalDate(date);
  return toLocalDate(DateTime(d.year, d.month, d.day + days));
}

String nextDay(String date) => _shift(date, 1);

String planHistoryStart(String today) => _shift(today, -planHistoryDays);

/// Enam hari sebelum [today] sampai [today].
List<String> lastSevenDays(String today) => [
  for (var i = 6; i >= 0; i--) _shift(today, -i),
];

List<DailyPlan> plansOn(Iterable<DailyPlan> plans, String date) => [
  for (final p in plans)
    if (p.planDate == date) p,
];

/// Rencana hari-hari lalu yang belum selesai. [ignoredThrough] = tanggal
/// terakhir yang user pilih untuk dibiarkan.
List<DailyPlan> leftovers(
  Iterable<DailyPlan> plans,
  String today, {
  String? ignoredThrough,
}) => [
  for (final p in plans)
    if (p.doneAt == null &&
        p.planDate.compareTo(today) < 0 &&
        (ignoredThrough == null || p.planDate.compareTo(ignoredThrough) > 0))
      p,
];
