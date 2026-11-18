import 'dart:math';

import 'package:drift/drift.dart';

import '../domain/reminder_parser.dart';
import '../../../core/database/app_database.dart';

/// Pengingat acara dari jurnal. Lokal di perangkat, tidak disinkronkan.
class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;
  static final _random = Random();

  /// Acara dari [today] ("YYYY-MM-DD") ke depan, terdekat dulu.
  Stream<List<Reminder>> watchUpcoming(String today) {
    final q = _db.select(_db.reminders)
      ..where((r) => r.eventDate.isBiggerOrEqualValue(today))
      ..orderBy([
        (r) => OrderingTerm(expression: r.eventDate),
        // Acara seharian (null) tampil lebih dulu di hari yang sama.
        (r) => OrderingTerm(expression: r.eventTime),
      ]);
    return q.watch();
  }

  Future<List<Reminder>> forEntry(String entryId) => (_db.select(
    _db.reminders,
  )..where((r) => r.entryId.equals(entryId))).get();

  Future<Reminder> add({
    required String? entryId,
    required String title,
    required String date,
    required String? time,
    required ReminderLead lead,
  }) async {
    final row = Reminder(
      id: newId(),
      entryId: entryId,
      title: title,
      eventDate: date,
      eventTime: time,
      lead: lead.code,
      notifId: _random.nextInt(0x7fffffff),
      createdAt: DateTime.now().toUtc(),
    );
    await _db.into(_db.reminders).insert(row);
    return row;
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.reminders)..where((r) => r.id.equals(id))).go();

  /// Hapus acara yang tanggalnya sudah lewat.
  Future<void> pruneBefore(String today) => (_db.delete(
    _db.reminders,
  )..where((r) => r.eventDate.isSmallerThanValue(today))).go();
}
