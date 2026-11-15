import '../../core/format.dart';
import '../../domain/models/reminder_parser.dart';
import '../db/app_database.dart';
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
    await _notifier.schedule(
      id: r.notifId,
      at: reminderFireAt(date, time, lead),
      title: notifTitle,
      body: notifBody,
      private: private,
    );
    return r;
  }

  Future<void> delete(Reminder r) async {
    await _notifier.cancel(r.notifId);
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
