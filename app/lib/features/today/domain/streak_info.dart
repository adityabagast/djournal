class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.isTodayActive,
    required this.activeDates,
  });

  final int currentStreak;
  final int longestStreak;
  final bool isTodayActive;
  final Set<String> activeDates;

  /// Hitung streak dari kumpulan tanggal aktivitas (format YYYY-MM-DD).
  factory StreakInfo.calculate({
    required Set<String> activeDates,
    required DateTime now,
  }) {
    if (activeDates.isEmpty) {
      return const StreakInfo(
        currentStreak: 0,
        longestStreak: 0,
        isTodayActive: false,
        activeDates: {},
      );
    }

    final todayStr = _formatDate(now);
    final today = DateTime(now.year, now.month, now.day);
    final yesterdayStr = _formatDate(_prevDay(today));
    final isTodayActive = activeDates.contains(todayStr);

    // Hitung current streak
    var streak = 0;
    var checkDate = isTodayActive ? today : _prevDay(today);

    // Jika kemarin dan hari ini tidak ada aktivitas, streak = 0
    if (!isTodayActive && !activeDates.contains(yesterdayStr)) {
      streak = 0;
    } else {
      while (activeDates.contains(_formatDate(checkDate))) {
        streak++;
        checkDate = _prevDay(checkDate);
      }
    }

    // Hitung longest streak secara keseluruhan
    final sortedDates = activeDates.toList()..sort();
    var longest = 0;
    var currentRun = 0;
    DateTime? prevDate;

    for (final dateStr in sortedDates) {
      // UTC supaya selisih hari selalu kelipatan 24 jam (tanpa efek DST).
      final parsed = DateTime.tryParse('${dateStr}T00:00:00Z');
      if (parsed == null) continue;

      if (prevDate == null) {
        currentRun = 1;
      } else {
        final diffDays = parsed.difference(prevDate).inDays;
        if (diffDays == 1) {
          currentRun++;
        } else if (diffDays > 1) {
          currentRun = 1;
        }
      }
      if (currentRun > longest) longest = currentRun;
      prevDate = parsed;
    }

    return StreakInfo(
      currentStreak: streak,
      longestStreak: longest,
      isTodayActive: isTodayActive,
      activeDates: activeDates,
    );
  }

  /// Hari sebelumnya lewat komponen tanggal; `subtract(Duration(days: 1))`
  /// bisa meleset di hari pergantian jam musim panas.
  static DateTime _prevDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
