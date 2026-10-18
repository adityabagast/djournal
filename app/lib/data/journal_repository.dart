import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/format.dart';
import 'db/app_database.dart';

class JournalRepository {
  JournalRepository(this._db);

  final AppDatabase _db;

  /// Semua entri aktif, tanggal terbaru dulu. Urutan di dalam satu hari
  /// diatur di UI lewat [entrySortKey].
  Stream<List<JournalEntry>> watchEntries() {
    final q = _db.select(_db.journalEntries)
      ..where((e) => e.deletedAt.isNull())
      ..orderBy([
        (e) => OrderingTerm(expression: e.entryDate, mode: OrderingMode.desc),
        (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  Future<String> saveEntry({
    String? id,
    required String entryDate,
    required String? entryTime,
    required int? mood,
    required String? title,
    required String? body,
    required List<String> tags,
    String? audioPath,
    int? audioDurationMs,
    String? audioTranscript,
  }) async {
    final now = DateTime.now().toUtc();
    String? clean(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    final tagsJson = tags.isEmpty ? null : jsonEncode(tags);
    final targetId = id ?? newId();

    if (id == null) {
      await _db
          .into(_db.journalEntries)
          .insert(
            JournalEntriesCompanion.insert(
              id: targetId,
              createdAt: now,
              updatedAt: now,
              entryDate: entryDate,
              entryTime: Value(entryTime),
              mood: Value(mood),
              title: Value(clean(title)),
              body: Value(clean(body)),
              tags: Value(tagsJson),
              audioPath: Value(audioPath),
              audioDurationMs: Value(audioDurationMs),
              audioTranscript: Value(clean(audioTranscript)),
            ),
          );
    } else {
      await (_db.update(
        _db.journalEntries,
      )..where((e) => e.id.equals(id))).write(
        JournalEntriesCompanion(
          updatedAt: Value(now),
          isDirty: const Value(true),
          entryDate: Value(entryDate),
          entryTime: Value(entryTime),
          mood: Value(mood),
          title: Value(clean(title)),
          body: Value(clean(body)),
          tags: Value(tagsJson),
          audioPath: Value(audioPath),
          audioDurationMs: Value(audioDurationMs),
          audioTranscript: Value(clean(audioTranscript)),
        ),
      );
    }
    return targetId;
  }

  Future<void> deleteEntry(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.journalEntries)..where((e) => e.id.equals(id))).write(
      JournalEntriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }
}

/// Kunci urut di dalam satu hari: jam kejadian, atau jam dibuat kalau
/// jam kosong (docs/data-model.md §4.5). Jam pengganti tidak ditampilkan.
String entrySortKey(JournalEntry e) => e.entryTime ?? hhmm(e.createdAt);

List<String> entryTags(JournalEntry e) {
  if (e.tags == null) return const [];
  return (jsonDecode(e.tags!) as List).cast<String>();
}

/// "teman, kerja , #kenangan" → ["teman", "kerja", "kenangan"]
List<String> parseTags(String input) => input
    .split(',')
    .map((t) => t.trim().replaceFirst(RegExp('^#'), ''))
    .where((t) => t.isNotEmpty)
    .toSet()
    .toList();

/// Mood harian = rata-rata mood entri hari itu, dibulatkan. null = tidak ada.
int? dayMood(Iterable<JournalEntry> entries, String date) {
  final moods = [
    for (final e in entries)
      if (e.entryDate == date && e.mood != null) e.mood!,
  ];
  if (moods.isEmpty) return null;
  return (moods.reduce((a, b) => a + b) / moods.length).round();
}
