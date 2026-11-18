import 'package:flutter/foundation.dart';

import '../../../core/format.dart';
import '../domain/reminder_parser.dart';
import '../../../core/database/app_database.dart';
import 'reminder_notifier.dart';
import 'reminder_repository.dart';

/// Menyimpan pengingat sekaligus menjadwalkan/membatalkan notifikasinya.
class ReminderService {
  ReminderService(this._repo, this._notifier);

  final ReminderRepository _repo;
  final ReminderNotifier _notifier;

  /// [notifTitle] dan [notifBody] sudah dalam bahasa user.
  Future<Reminder> add({
    required String? entryId,
    required String title,
    required String date,
    required String? time,
    required ReminderLead lead,
    required String notifTitle,
    required String notifBody,
    required bool private,
  }) async {
    final r = await _repo.add(
      entryId: entryId,
      title: title,
      date: date,
      time: time,
      lead: lead,
    );
    try {
      await _notifier.schedule(
        id: r.notifId,
        at: reminderFireAt(date, time, lead),
        title: notifTitle,
        body: notifBody,
        private: private,
      );
    } catch (e) {
      // Pengingat tetap tersimpan dan tampil di Hari Ini walau notifikasi
      // gagal dijadwalkan. Isi pengingat tidak ikut dicatat ke log.
      debugPrint('Jadwal notifikasi gagal: ${e.runtimeType}');
    }
    return r;
  }

  Future<void> delete(Reminder r) async {
    try {
      await _notifier.cancel(r.notifId);
    } catch (e) {
      debugPrint('Batal notifikasi gagal: ${e.runtimeType}');
    }
    await _repo.delete(r.id);
  }

  /// Entri jurnal dihapus: pengingat darinya ikut dihapus.
  Future<void> deleteForEntry(String entryId) async {
    for (final r in await _repo.forEntry(entryId)) {
      await delete(r);
    }
  }

  Future<void> pruneOld() => _repo.pruneBefore(toLocalDate(DateTime.now()));
}
