import 'package:djournal/core/attachments/attachment_repository.dart';
import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/core/format.dart';
import 'package:djournal/core/theme.dart';
import 'package:djournal/features/journal/data/journal_repository.dart';
import 'package:djournal/features/journal/presentation/entry_form_screen.dart';
import 'package:djournal/features/journal/presentation/note/note_parts.dart';
import 'package:djournal/features/lock/providers/lock_controller.dart';
import 'package:djournal/features/money/data/money_repository.dart';
import 'package:djournal/features/money/domain/money_snapshot.dart';
import 'package:djournal/features/reminders/data/reminder_notifier.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeLock extends LockController {
  @override
  LockState build() => const LockState(
    loading: false,
    pinEnabled: false,
    biometricEnabled: false,
    biometricAvailable: false,
    locked: false,
  );
}

class _FakeNotifier implements ReminderNotifier {
  @override
  bool get supported => false;

  @override
  dynamic noSuchMethod(Invocation i) => Future<void>.value();
}

void main() {
  late AppDatabase db;
  late JournalRepository journal;
  late MoneyRepository money;
  final today = toLocalDate(DateTime.now());

  setUpAll(initializeDateFormatting);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    journal = JournalRepository(db);
    money = MoneyRepository(db);
  });

  tearDown(() => db.close());

  Future<MoneySnapshot> snapshot() async => MoneySnapshot(
    wallets: await money.watchWallets().first,
    categories: await money.watchCategories().first,
    transactions: await money.watchTransactions().first,
    budgets: await money.watchBudgets().first,
  );

  /// Buka catatan di atas layar "Beranda" supaya tombol kembali ada.
  Future<void> open(
    WidgetTester tester, {
    JournalEntry? existing,
    bool startEditing = false,
    String? initialTitle,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final snap = (await tester.runAsync(snapshot))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          moneySnapshotProvider.overrideWithValue(AsyncValue.data(snap)),
          hideAmountsProvider.overrideWith((ref) => Stream.value(false)),
          lockProvider.overrideWith(_FakeLock.new),
          reminderNotifierProvider.overrideWithValue(_FakeNotifier()),
          attachmentRepositoryProvider.overrideWithValue(
            AttachmentRepository(db),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => EntryFormScreen.open(
                  context,
                  existing: existing,
                  startEditing: startEditing,
                  initialTitle: initialTitle,
                ),
                child: const Text('Beranda'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
  }

  /// Drift memakai timer asli: beri waktu di luar fake async.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await settle(tester);
  }

  Future<JournalEntry> seed(WidgetTester tester, {String body = 'Isi lama.'}) =>
      tester
          .runAsync(() async {
            await journal.saveEntry(
              entryDate: today,
              entryTime: '08:00',
              mood: 4,
              title: 'Judul lama',
              body: body,
              tags: const ['kopi'],
            );
            return (await journal.watchEntries().first).single;
          })
          .then((e) => e!);

  final titleField = find.byKey(const Key('noteTitle'));
  final bodyField = find.byKey(const Key('noteBody'));

  testWidgets('catatan baru: tulis, simpan, lalu tampil untuk dibaca', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(titleField, 'Ngopi sore');
    await tester.enterText(bodyField, 'Duduk sebentar di kafe.');
    await tapText(tester, 'Simpan');

    expect(titleField, findsNothing);
    expect(find.text('Ngopi sore'), findsOneWidget);
    expect(find.text('Duduk sebentar di kafe.'), findsOneWidget);
    expect(find.byTooltip('Edit catatan'), findsOneWidget);
    final rows = (await tester.runAsync(() => journal.watchEntries().first))!;
    expect(rows.single.title, 'Ngopi sore');

    // Simpan lagi tidak membuat entri kedua.
    await tester.tap(find.text('Duduk sebentar di kafe.'));
    await settle(tester);
    await tester.enterText(bodyField, 'Duduk lama di kafe.');
    await tapText(tester, 'Simpan');
    final after = (await tester.runAsync(() => journal.watchEntries().first))!;
    expect(after.single.body, 'Duduk lama di kafe.');
    await settle(tester);
  });

  testWidgets('catatan kosong tidak disimpan', (tester) async {
    await open(tester);
    await tapText(tester, 'Simpan');
    expect(find.text('Tulis judul atau cerita dulu ya.'), findsOneWidget);
    // Tidak ada isi: kembali langsung keluar.
    await back(tester);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('entri lama dibuka untuk dibaca dulu', (tester) async {
    final e = await seed(tester);
    await open(tester, existing: e);
    expect(titleField, findsNothing);
    expect(find.text('Judul lama'), findsOneWidget);
    expect(find.text('#kopi'), findsOneWidget);
    expect(find.text('Baik'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit catatan'));
    await settle(tester);
    expect(titleField, findsOneWidget);
    // Tanpa perubahan: kembali ke mode baca, lalu keluar.
    await back(tester);
    expect(titleField, findsNothing);
    await back(tester);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('jurnal lama: dibaca tidak mengubah apa pun, diedit hanya '
      'mengubah isinya', (tester) async {
    final attachments = AttachmentRepository(db);
    final (old, photos) = (await tester.runAsync(() async {
      final id = await journal.saveEntry(
        entryDate: '2025-03-10',
        entryTime: '07:15',
        mood: 2,
        title: 'Jurnal lama',
        body: 'Makan siang 38rb. Besok jam 9 pagi rapat.',
        tags: const ['kerja', 'pagi'],
        audioDurationMs: 42000,
        audioTranscript: 'Halo.',
      );
      await attachments.syncEntryAttachments(id, ['/a.jpg', '/b.jpg']);
      return (
        (await journal.watchEntries().first).single,
        await attachments.getAttachmentsForEntry(id),
      );
    }))!;
    Future<(JournalEntry, List<Attachment>)> now() async =>
        (await tester.runAsync(
          () async => (
            (await journal.watchEntries().first).single,
            await attachments.getAttachmentsForEntry(old.id),
          ),
        ))!;

    await open(tester, existing: old);
    await settle(tester);
    expect(find.byType(NotePhotos), findsOneWidget);
    await back(tester);
    expect(find.text('Beranda'), findsOneWidget);
    expect((await now()).$1, old);
    expect((await now()).$2, photos);

    // Edit lalu simpan: isi berubah, sisanya utuh, tidak ada transaksi atau
    // pengingat yang dibuat sendiri.
    await tapText(tester, 'Beranda');
    await tester.tap(find.byTooltip('Edit catatan'));
    await settle(tester);
    await tester.enterText(bodyField, '${old.body} Tambahan.');
    await tapText(tester, 'Simpan');
    final (e, atts) = await now();
    expect(
      e.copyWith(
        body: Value(old.body),
        updatedAt: old.updatedAt,
        isDirty: old.isDirty,
      ),
      old,
    );
    expect(e.body, '${old.body} Tambahan.');
    expect(atts, photos);
    expect(
      await tester.runAsync(() => money.watchTransactions().first),
      isEmpty,
    );
    await settle(tester);
  });

  testWidgets('keluar dengan tulisan belum disimpan: lanjut atau buang', (
    tester,
  ) async {
    final e = await seed(tester);
    await open(tester, existing: e, startEditing: true);
    await tester.enterText(bodyField, 'Diubah.');
    await back(tester);
    expect(find.text('Simpan catatan ini?'), findsOneWidget);

    await tapText(tester, 'Lanjut menulis');
    expect(find.text('Diubah.'), findsOneWidget);

    await back(tester);
    await tapText(tester, 'Buang');
    expect(find.text('Beranda'), findsOneWidget);
    final rows = (await tester.runAsync(() => journal.watchEntries().first))!;
    expect(rows.single.body, 'Isi lama.');
  });

  testWidgets('judul dari Kocok ide tidak dianggap perubahan', (tester) async {
    await open(tester, initialTitle: 'Apa yang kamu syukuri?');
    await back(tester);
    expect(find.text('Simpan catatan ini?'), findsNothing);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('mood dan tag lewat panel', (tester) async {
    await open(tester);
    await tester.enterText(bodyField, 'Cerita.');
    await tester.tap(find.bySemanticsLabel('Mood').last);
    await settle(tester);
    await tapText(tester, 'Senang');

    await tester.tap(find.bySemanticsLabel('Tag'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('noteTag')), 'teman,');
    await settle(tester);
    // Tag yang belum ditambahkan ikut tersimpan.
    await tester.enterText(find.byKey(const Key('noteTag')), '#kerja');
    await tapText(tester, 'Simpan');

    final e = (await tester.runAsync(() => journal.watchEntries().first))!
        .single;
    expect(e.mood, 5);
    expect(entryTags(e), ['teman', 'kerja']);
    await settle(tester);
  });

  testWidgets('transaksi di cerita dicatat bersama catatan', (tester) async {
    await open(tester);
    await tester.enterText(bodyField, 'Beli es kopi 28rb, parkir 2rb.');
    await settle(tester);
    expect(find.textContaining('2 transaksi'), findsOneWidget);
    Future<List<MoneyTx>> txs() async =>
        (await tester.runAsync(() => money.watchTransactions().first))!;

    await tapText(tester, 'Catat semua');
    // Belum ditulis ke database sebelum Simpan.
    expect(await txs(), isEmpty);

    await tapText(tester, 'Simpan');
    final saved = await txs();
    expect(saved.map((t) => t.amount).toSet(), {28000, 2000});
    expect(saved.map((t) => t.localDate).toSet(), {today});
    expect(saved.every((t) => t.type == 'expense'), isTrue);
    expect(find.textContaining('2 transaksi dicatat'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('foto catatan jadi nota, tiap transaksi notanya sendiri', (
    tester,
  ) async {
    final attachments = AttachmentRepository(db);
    final e = (await tester.runAsync(() async {
      final id = await journal.saveEntry(
        entryDate: today,
        entryTime: '10:00',
        mood: 3,
        title: 'Belanja',
        body: 'Kopi 25rb, roti 12rb.',
        tags: const [],
      );
      await attachments.syncEntryAttachments(id, ['/n1.jpg', '/n2.jpg']);
      return (await journal.watchEntries().first).single;
    }))!;
    await open(tester, existing: e, startEditing: true);
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Uang'));
    await settle(tester);

    Future<void> openTx(String tx) async {
      final row = find.text(tx).last;
      await tester.ensureVisible(row);
      await settle(tester);
      await tapText(tester, tx);
    }

    Future<void> pick(int photo) async {
      final p = find.bySemanticsLabel(RegExp('^Pakai foto $photo'));
      await tester.ensureVisible(p);
      await settle(tester);
      await tester.tap(p);
      await settle(tester);
      await tester.ensureVisible(find.text('Catat').last);
      await settle(tester);
      await tapText(tester, 'Catat');
    }

    await openTx('Kopi');
    await pick(1);
    await openTx('Roti');
    // Foto 1 sudah dipakai Kopi; terlihat sebelum memilih.
    expect(find.text('Dipakai Kopi'), findsOneWidget);
    await pick(2);

    await back(tester); // tutup panel
    await tapText(tester, 'Simpan');
    final rows = (await tester.runAsync(
      () => money.watchTransactions().first,
    ))!;
    final paths = {
      for (final t in rows)
        t.note: (await tester.runAsync(
          () => attachments.getAttachmentForTx(t.id),
        ))?.localPath,
    };
    expect(paths, {'Kopi': '/n1.jpg', 'Roti': '/n2.jpg'});
    // Foto catatan tidak berubah.
    final entryPhotos = (await tester.runAsync(
      () => attachments.getAttachmentsForEntry(e.id),
    ))!;
    expect(entryPhotos.map((a) => a.localPath), ['/n1.jpg', '/n2.jpg']);
    await settle(tester);
  });

  testWidgets('usulan transaksi yang diabaikan tidak dicatat', (tester) async {
    await open(tester);
    await tester.enterText(bodyField, 'Kopi 25rb.');
    await settle(tester);
    await tester.tap(find.byTooltip('Jangan catat'));
    await settle(tester);
    await tapText(tester, 'Simpan');
    final rows = (await tester.runAsync(
      () => money.watchTransactions().first,
    ))!;
    expect(rows, isEmpty);
    await settle(tester);
  });

  testWidgets('tambah transaksi manual lewat panel Uang', (tester) async {
    await open(tester);
    await tester.enterText(bodyField, 'Cerita tanpa nominal.');
    await tester.tap(find.bySemanticsLabel('Uang'));
    await settle(tester);
    await tapText(tester, 'Tambah');
    await tester.enterText(find.byKey(const Key('txDraftAmount')), '15000');
    await tester.enterText(find.byKey(const Key('txDraftNote')), 'Tip');
    await tester.ensureVisible(find.text('Catat').last);
    await settle(tester);
    await tapText(tester, 'Catat');
    expect(find.text('Dicatat'), findsOneWidget);

    // Transaksi yang belum disimpan ikut dijaga saat keluar.
    await back(tester); // tutup panel
    await back(tester);
    expect(find.text('Simpan catatan ini?'), findsOneWidget);
    await tapText(tester, 'Simpan');
    final rows = (await tester.runAsync(
      () => money.watchTransactions().first,
    ))!;
    expect(rows.single.note, 'Tip');
    expect(rows.single.amount, 15000);
    await settle(tester);
  });
}
