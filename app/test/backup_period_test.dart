import 'package:djournal/domain/models/backup_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupPeriod', () {
    test('all() mencakup semua tanggal', () {
      const period = BackupPeriod.all();
      expect(period.includes(DateTime(2020, 1, 1)), isTrue);
      expect(period.includes(DateTime(2026, 10, 18)), isTrue);
      expect(period.includes(DateTime(2030, 12, 31)), isTrue);
      expect(period.includesYmd('2026-10-18'), isTrue);
    });

    test('thisYear() hanya mencakup tahun yang ditentukan', () {
      final period = BackupPeriod.thisYear(DateTime(2026, 6, 15));
      expect(period.includes(DateTime(2026, 1, 1)), isTrue);
      expect(period.includes(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(period.includes(DateTime(2025, 12, 31)), isFalse);
      expect(period.includes(DateTime(2027, 1, 1)), isFalse);
      expect(period.includesYmd('2026-05-20'), isTrue);
      expect(period.includesYmd('2025-05-20'), isFalse);
    });

    test('thisMonth() hanya mencakup bulan yang ditentukan', () {
      final period = BackupPeriod.thisMonth(DateTime(2026, 10, 18));
      expect(period.includes(DateTime(2026, 10, 1)), isTrue);
      expect(period.includes(DateTime(2026, 10, 31, 23, 59)), isTrue);
      expect(period.includes(DateTime(2026, 9, 30)), isFalse);
      expect(period.includes(DateTime(2026, 11, 1)), isFalse);
      expect(period.includesYmd('2026-10-18'), isTrue);
      expect(period.includesYmd('2026-09-18'), isFalse);
    });

    test('custom() mencakup rentang tanggal awal s/d akhir', () {
      final period = BackupPeriod.custom(
        DateTime(2026, 3, 10),
        DateTime(2026, 3, 20),
      );
      expect(period.includes(DateTime(2026, 3, 10)), isTrue);
      expect(period.includes(DateTime(2026, 3, 15)), isTrue);
      expect(period.includes(DateTime(2026, 3, 20, 23, 59)), isTrue);
      expect(period.includes(DateTime(2026, 3, 9)), isFalse);
      expect(period.includes(DateTime(2026, 3, 21)), isFalse);
      expect(period.includesYmd('2026-03-12'), isTrue);
      expect(period.includesYmd('2026-03-25'), isFalse);
    });
  });
}
