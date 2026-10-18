import '../../core/format.dart';
import '../../l10n/app_localizations.dart';

enum BackupPeriodType {
  all,
  thisYear,
  thisMonth,
  custom,
}

/// Mewakili rentang data yang dipilih untuk cadangan (Google Drive maupun lokal).
class BackupPeriod {
  const BackupPeriod({
    required this.type,
    this.startDate,
    this.endDate,
  });

  final BackupPeriodType type;
  final DateTime? startDate;
  final DateTime? endDate;

  const BackupPeriod.all()
      : type = BackupPeriodType.all,
        startDate = null,
        endDate = null;

  factory BackupPeriod.thisYear([DateTime? now]) {
    final n = now ?? DateTime.now();
    return BackupPeriod(
      type: BackupPeriodType.thisYear,
      startDate: DateTime(n.year, 1, 1),
      endDate: DateTime(n.year, 12, 31, 23, 59, 59),
    );
  }

  factory BackupPeriod.thisMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    final lastDay = DateTime(n.year, n.month + 1, 0).day;
    return BackupPeriod(
      type: BackupPeriodType.thisMonth,
      startDate: DateTime(n.year, n.month, 1),
      endDate: DateTime(n.year, n.month, lastDay, 23, 59, 59),
    );
  }

  factory BackupPeriod.custom(DateTime start, DateTime end) {
    return BackupPeriod(
      type: BackupPeriodType.custom,
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  bool includes(DateTime date) {
    if (type == BackupPeriodType.all) return true;
    if (startDate != null && date.isBefore(startDate!)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }

  bool includesYmd(String ymd) {
    if (type == BackupPeriodType.all) return true;
    try {
      final date = parseLocalDate(ymd);
      return includes(date);
    } catch (_) {
      return true;
    }
  }

  String label(AppLocalizations l) {
    switch (type) {
      case BackupPeriodType.all:
        return l.rangeAll;
      case BackupPeriodType.thisYear:
        return '${l.rangeThisYear} (${startDate?.year ?? DateTime.now().year})';
      case BackupPeriodType.thisMonth:
        return l.rangeThisMonth;
      case BackupPeriodType.custom:
        if (startDate != null && endDate != null) {
          return '${toLocalDate(startDate!)} s/d ${toLocalDate(endDate!)}';
        }
        return l.rangeCustom;
    }
  }
}

