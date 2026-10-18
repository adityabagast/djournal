import 'package:djournal/core/theme.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/data/search.dart';
import 'package:djournal/data/sync/row_json.dart';
import 'package:djournal/features/journal/entry_rows.dart';
import 'package:djournal/features/journal/voice/voice_player_card.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapWithTheme(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Voice Note & Transcription', () {
    test('saveEntry dan watchEntries menyimpan kolom audio dengan benar', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = JournalRepository(db);

      await repo.saveEntry(
        entryDate: '2026-10-14',
        entryTime: '08:30',
        mood: 5,
        title: 'Rekaman Pagi',
        body: 'Cerita pagi hari yang indah.',
        tags: ['pagi', 'suara'],
        audioPath: '/storage/emulated/0/Android/data/voice_notes/test.m4a',
        audioDurationMs: 42000,
        audioTranscript: 'Hari ini saya sangat bersemangat mengerjakan fitur baru Nyawtat.',
      );

      final entries = await repo.watchEntries().first;
      expect(entries.length, 1);
      final entry = entries.first;
      expect(entry.title, 'Rekaman Pagi');
      expect(entry.audioPath, '/storage/emulated/0/Android/data/voice_notes/test.m4a');
      expect(entry.audioDurationMs, 42000);
      expect(entry.audioTranscript, 'Hari ini saya sangat bersemangat mengerjakan fitur baru Nyawtat.');
    });

    test('entryToJson dan entryFromJson mempertahankan field audio', () {
      final now = DateTime.utc(2026, 10, 14, 8, 30);
      final entry = JournalEntry(
        id: 'voice-entry-1',
        createdAt: now,
        updatedAt: now,
        isDirty: true,
        entryDate: '2026-10-14',
        entryTime: '08:30',
        mood: 5,
        title: 'Tes Audio',
        body: 'Catatan audio',
        tags: '["voice"]',
        audioPath: '/path/to/voice.m4a',
        audioDurationMs: 35000,
        audioTranscript: 'Transkripsi otomatis kata-kata',
      );

      final json = entryToJson(entry);
      expect(json['audioPath'], '/path/to/voice.m4a');
      expect(json['audioDurationMs'], 35000);
      expect(json['audioTranscript'], 'Transkripsi otomatis kata-kata');

      final reconstructed = entryFromJson(json);
      expect(reconstructed.id, entry.id);
      expect(reconstructed.audioPath, entry.audioPath);
      expect(reconstructed.audioDurationMs, entry.audioDurationMs);
      expect(reconstructed.audioTranscript, entry.audioTranscript);
    });

    test('Pencarian menemukan jurnal berdasarkan kata di transkripsi suara', () {
      final now = DateTime.utc(2026, 10, 14);
      final entries = [
        JournalEntry(
          id: '1',
          createdAt: now,
          updatedAt: now,
          isDirty: false,
          entryDate: '2026-10-14',
          title: 'Hari Biasa',
          body: 'Tidak ada yang spesial',
          audioTranscript: 'Sempat mampir beli es krim vanila di minimarket',
        ),
        JournalEntry(
          id: '2',
          createdAt: now,
          updatedAt: now,
          isDirty: false,
          entryDate: '2026-10-14',
          title: 'Olahraga',
          body: 'Lari 5km pagi hari',
        ),
      ];

      final results = searchAll(
        query: 'es krim',
        entries: entries,
        money: MoneySnapshot(
          wallets: [],
          categories: [],
          transactions: [],
          budgets: [],
        ),
        categoryName: (c) => c.name,
        transferLabel: 'Transfer',
      );

      expect(results.entryCount, 1);
      expect(results.hits.first.entry?.id, '1');
    });

    testWidgets('VoicePlayerCard menampilkan widget fallback bila audio belum ada', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const VoicePlayerCard(
            audioPath: '/dummy/nonexistent.m4a',
            durationMs: 30000,
            transcript: 'Selamat pagi teman-teman semuanya',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(VoicePlayerCard), findsOneWidget);
    });

    testWidgets('EntryTimelineRow menampilkan badge catatan suara bila ada audio', (tester) async {
      final now = DateTime.utc(2026, 10, 14, 8, 30);
      final entry = JournalEntry(
        id: 'voice-entry',
        createdAt: now,
        updatedAt: now,
        isDirty: false,
        entryDate: '2026-10-14',
        entryTime: '08:30',
        title: 'Cerita Sore',
        audioPath: '/path/audio.m4a',
        audioDurationMs: 15000,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          EntryTimelineRow(
            entry: entry,
            onTap: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Catatan suara'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });
  });
}

