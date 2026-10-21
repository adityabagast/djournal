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
    final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));
    final isTodayActive = activeDates.contains(todayStr);

    // Hitung current streak
    var streak = 0;
    var checkDate = isTodayActive ? now : now.subtract(const Duration(days: 1));

    // Jika kemarin dan hari ini tidak ada aktivitas, streak = 0
    if (!isTodayActive && !activeDates.contains(yesterdayStr)) {
      streak = 0;
    } else {
      while (activeDates.contains(_formatDate(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Hitung longest streak secara keseluruhan
    final sortedDates = activeDates.toList()..sort();
    var longest = 0;
    var currentRun = 0;
    DateTime? prevDate;

    for (final dateStr in sortedDates) {
      final parsed = DateTime.tryParse(dateStr);
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

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
