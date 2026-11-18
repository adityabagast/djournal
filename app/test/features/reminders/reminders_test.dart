import 'package:djournal/core/format.dart';
import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/features/reminders/data/reminder_notifier.dart';
import 'package:djournal/features/reminders/data/reminder_repository.dart';
import 'package:djournal/features/reminders/data/reminder_service.dart';
import 'package:djournal/features/reminders/domain/reminder_parser.dart';
import 'package:djournal/features/reminders/presentation/reminder_suggestions.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotifier implements ReminderNotifier {
  final scheduled = <int, (DateTime, String, String, bool)>{};

  @override
  bool get supported => false;

  @override
  Future<bool> isAllowed() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required bool private,
  }) async => scheduled[id] = (at, title, body, private);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}

/// Seperti plugin notifikasi yang gagal init (mis. ikon hilang di build rilis).
class _BrokenNotifier implements ReminderNotifier {
  @override
  bool get supported => true;

  @override
  Future<bool> isAllowed() async => throw StateError('init gagal');

  @override
  Future<bool> requestPermission() async => throw StateError('init gagal');

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required bool private,
  }) async => throw StateError('init gagal');

  @override
  Future<void> cancel(int id) async => throw StateError('init gagal');
}

void main() {
  group('ReminderService dengan notifikasi rusak', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('pengingat tetap tersimpan dan bisa dihapus', () async {
      final service = ReminderService(ReminderRepository(db), _BrokenNotifier());
      final r = await service.add(
        entryId: 'e1',
        title: 'Servis motor',
        date: '2030-01-10',
        time: '09:00',
        lead: ReminderLead.hourBefore,
        notifTitle: 'judul',
        notifBody: 'isi',
        private: false,
      );
      expect(await db.select(db.reminders).get(), hasLength(1));
      await service.delete(r);
      expect(await db.select(db.reminders).get(), isEmpty);
    });
  });

  testWidgets('Ingatkan aku tetap jalan walau notifikasi gagal', (
    tester,
  ) async {
    final controller = ReminderSuggestionController();
    const text = 'Besok jam 9 pagi servis motor.';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderNotifierProvider.overrideWithValue(_BrokenNotifier()),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReminderSuggestions(controller: controller, text: text),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingatkan aku'));
    await tester.pumpAndSettle();
    expect(find.text('Pengingat aktif · 1 jam sebelum'), findsOneWidget);
    expect(controller.acceptedDrafts(text, DateTime.now()), hasLength(1));
  });

  group('ReminderService', () {
    late AppDatabase db;
    late ReminderRepository repo;
    late _FakeNotifier notifier;
    late ReminderService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ReminderRepository(db);
      notifier = _FakeNotifier();
      service = ReminderService(repo, notifier);
    });

    tearDown(() => db.close());

    Future<Reminder> add(String date, String? time, {String? entry}) =>
        service.add(
          entryId: entry,
          title: 'Acara $date',
          date: date,
          time: time,
          lead: time == null ? ReminderLead.atEvent : ReminderLead.hourBefore,
          notifTitle: 'judul',
          notifBody: 'isi',
          private: true,
        );

    test('simpan menjadwalkan notifikasi, hapus membatalkannya', () async {
      final r = await add('2030-01-10', '13:00');
      expect(notifier.scheduled[r.notifId], (
        DateTime(2030, 1, 10, 12),
        'judul',
        'isi',
        true,
      ));

      await service.delete(r);
      expect(notifier.scheduled, isEmpty);
      expect(await repo.watchUpcoming('2030-01-01').first, isEmpty);
    });

    test('acara mendatang terurut, yang lewat dibuang', () async {
      await add('2030-01-12', null);
      await add('2030-01-10', '15:00');
      await add('2030-01-10', '09:00');
      await add('2029-12-31', null);

      final rows = await repo.watchUpcoming('2030-01-01').first;
      expect(rows.map((r) => '${r.eventDate} ${r.eventTime}'), [
        '2030-01-10 09:00',
        '2030-01-10 15:00',
        '2030-01-12 null',
      ]);

      await repo.pruneBefore('2030-01-01');
      expect(await db.select(db.reminders).get(), hasLength(3));
    });

    test('hapus entri ikut menghapus pengingatnya', () async {
      await add('2030-01-10', '09:00', entry: 'e1');
      await add('2030-01-11', null, entry: 'e1');
      final keep = await add('2030-01-12', null, entry: 'e2');

      await service.deleteForEntry('e1');
      final rows = await db.select(db.reminders).get();
      expect(rows.map((r) => r.id), [keep.id]);
      expect(notifier.scheduled.keys, [keep.notifId]);
    });
  });

  testWidgets('saran pengingat: terima, batal, abaikan', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = ReminderSuggestionController();
    final tomorrow = toLocalDate(
      DateTime.now().add(const Duration(days: 1)),
    );
    const text =
        'Pagi ini beres-beres kamar. Besok jam 9 pagi servis motor. '
        'Lusa jam 3 sore rapat RT.';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderNotifierProvider.overrideWithValue(_FakeNotifier()),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReminderSuggestions(controller: controller, text: text),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servis motor'), findsOneWidget);
    expect(find.text('Rapat RT'), findsOneWidget);
    expect(find.text('Besok'), findsOneWidget);
    expect(find.text('Ingatkan aku'), findsNWidgets(2));
    expect(controller.acceptedDrafts(text, DateTime.now()), isEmpty);

    await tester.tap(find.text('Ingatkan aku').first);
    await tester.pumpAndSettle();
    expect(find.text('Pengingat aktif · 1 jam sebelum'), findsOneWidget);
    final accepted = controller.acceptedDrafts(text, DateTime.now());
    expect(accepted.map((d) => '${d.title} ${d.date} ${d.time}'), [
      'Servis motor $tomorrow 09:00',
    ]);

    await tester.tap(find.text('Abaikan'));
    await tester.pumpAndSettle();
    expect(find.text('Rapat RT'), findsNothing);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(controller.acceptedDrafts(text, DateTime.now()), isEmpty);
  });

  testWidgets('tanpa rencana menampilkan petunjuk', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ReminderSuggestions(
              controller: ReminderSuggestionController(),
              text: 'Hari ini santai saja di rumah.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada tanggal atau jam'), findsOneWidget);
  });
}
