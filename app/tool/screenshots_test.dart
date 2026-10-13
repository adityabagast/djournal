// Bukan test sungguhan: alat untuk membuat screenshot README dari layar app
// yang asli, diisi data contoh (bukan data pribadi). Hasil: docs/screenshots/.
// Jalankan dari folder app/:
//   flutter test tool/screenshots_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:djournal/core/format.dart';
import 'package:djournal/core/theme.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/home_widget_sync.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/data/security/lock_controller.dart';
import 'package:djournal/data/settings_repository.dart';
import 'package:djournal/data/sync/account_controller.dart';
import 'package:djournal/features/journal/entry_form_screen.dart';
import 'package:djournal/features/lock/lock_screen.dart';
import 'package:djournal/features/money/categories_screen.dart';
import 'package:djournal/features/money/wallets_screen.dart';
import 'package:djournal/features/search/search_screen.dart';
import 'package:djournal/features/shell/home_shell.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _outDir = '../docs/screenshots';
const _size = Size(390, 844);
const _pixelRatio = 2.0;

class _FakeAccount extends AccountController {
  @override
  AccountState build() => const AccountState(loading: false);

  @override
  Future<void> sync() async {}
}

class _FakeLock extends LockController {
  @override
  LockState build() => const LockState(
    loading: false,
    pinEnabled: true,
    biometricEnabled: true,
    biometricAvailable: true,
    locked: true,
  );

  @override
  Future<bool> unlockWithBiometric(String reason) async => false;
}

/// Pengganti tabel app_settings (pencarian terakhir): database drift asli
/// macet di testWidgets.
class _FakeSettings implements SettingsRepository {
  final _values = <String, String>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<String?> watch(String key) async* {
    yield _values[key];
    await for (final _ in _changes.stream) {
      yield _values[key];
    }
  }

  @override
  Future<void> set(String key, String value) async {
    _values[key] = value;
    _changes.add(null);
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
    _changes.add(null);
  }
}

late MoneySnapshot _snap;
late List<JournalEntry> _entries;

/// Data contoh relatif terhadap hari ini, supaya layar "Hari Ini" selalu terisi.
Future<void> _buildDemoData() async {
  final db = AppDatabase(NativeDatabase.memory());
  final money = MoneyRepository(db);
  final journal = JournalRepository(db);
  final now = DateTime.now();
  DateTime at(int daysAgo, int h, int m) =>
      DateTime(now.year, now.month, now.day - daysAgo, h, m);
  String day(int daysAgo) => toLocalDate(at(daysAgo, 12, 0));

  final cash = (await money.watchWallets().first).single;
  await money.updateWallet(
    id: cash.id,
    name: cash.name,
    type: cash.type,
    openingBalance: 350000,
  );
  await money.addWallet(name: 'BCA', type: 'bank', openingBalance: 4500000);
  await money.addWallet(name: 'GoPay', type: 'ewallet', openingBalance: 250000);
  final wallets = {for (final w in await money.watchWallets().first) w.name: w};
  final cats = {
    for (final c in await money.watchCategories().first) c.systemKey: c,
  };

  final month = toLocalDate(now).substring(0, 7);
  for (final (key, amount) in [
    ('food', 1500000),
    ('transport', 600000),
    ('shopping', 800000),
    ('entertainment', 300000),
    ('bills', 1000000),
  ]) {
    await money.setBudget(
      categoryId: cats[key]!.id,
      startMonth: month,
      amount: amount,
    );
  }

  final txs = [
    (
      'income',
      8500000,
      'BCA',
      'salary',
      'Gaji bulan ini',
      DateTime(now.year, now.month, 1, 9),
    ),
    ('expense', 25000, 'GoPay', 'food', 'Kopi susu', at(0, 7, 30)),
    ('expense', 38000, 'Tunai', 'food', 'Makan siang', at(0, 12, 15)),
    ('expense', 22000, 'GoPay', 'transport', 'Ojek pulang', at(0, 18, 20)),
    ('expense', 245000, 'BCA', 'shopping', 'Belanja mingguan', at(1, 10, 5)),
    ('expense', 50000, 'Tunai', 'transport', 'Bensin', at(1, 16, 40)),
    (
      'expense',
      60000,
      'GoPay',
      'entertainment',
      'Nonton bioskop',
      at(2, 19, 30),
    ),
    ('expense', 55000, 'Tunai', 'food', 'Makan malam', at(2, 21, 0)),
    ('expense', 200000, 'BCA', 'bills', 'Token listrik', at(3, 8, 10)),
    ('expense', 330000, 'BCA', 'bills', 'Internet bulanan', at(5, 9, 0)),
    ('expense', 42000, 'Tunai', 'food', 'Sarapan bubur', at(4, 7, 15)),
  ];
  for (final (type, amount, wallet, cat, note, occurredAt) in txs) {
    await money.saveTransaction(
      type: type,
      amount: amount,
      walletId: wallets[wallet]!.id,
      categoryId: cats[cat]!.id,
      note: note,
      occurredAt: occurredAt,
    );
  }
  await money.saveTransaction(
    type: 'transfer',
    amount: 300000,
    walletId: wallets['BCA']!.id,
    toWalletId: wallets['Tunai']!.id,
    categoryId: null,
    note: 'Tarik tunai',
    occurredAt: at(0, 8, 0),
  );

  final entries = [
    (
      0,
      '17:30',
      5,
      'Jalan sore di taman',
      'Suara burung sore ini menenangkan sekali setelah seharian di depan laptop.',
      ['santai', 'suara'],
      'demo_voice.m4a',
      42000,
      'Suara burung sore ini menenangkan sekali setelah seharian di depan laptop.',
    ),
    (
      0,
      '07:10',
      4,
      'Pagi yang tenang',
      'Bangun lebih awal, sempat jalan kaki sebentar sebelum kerja. Udara masih sejuk.',
      ['pagi', 'olahraga'],
      null,
      null,
      null,
    ),
    (
      0,
      '21:30',
      3,
      'Rapat panjang',
      'Capek, tapi rilis minggu ini akhirnya jalan. Besok mau tidur lebih cepat.',
      ['kerja'],
      null,
      null,
      null,
    ),
    (
      1,
      '20:00',
      5,
      'Masak bareng keluarga',
      'Coba resep soto ayam dari Ibu. Habis dalam sekejap!',
      ['keluarga'],
      null,
      null,
      null,
    ),
    (
      2,
      '22:15',
      4,
      'Nonton film',
      'Filmnya seru, popcorn-nya kemahalan.',
      <String>[],
      null,
      null,
      null,
    ),
    (
      4,
      null,
      2,
      'Kurang tidur',
      'Begadang menyelesaikan tugas, seharian jadi lemas.',
      <String>[],
      null,
      null,
      null,
    ),
  ];
  for (final (
        daysAgo,
        time,
        mood,
        title,
        body,
        tags,
        audioPath,
        audioDurationMs,
        audioTranscript
      ) in entries) {
    await journal.saveEntry(
      entryDate: day(daysAgo),
      entryTime: time,
      mood: mood,
      title: title,
      body: body,
      tags: tags,
      audioPath: audioPath,
      audioDurationMs: audioDurationMs,
      audioTranscript: audioTranscript,
    );
  }

  _snap = MoneySnapshot(
    wallets: await money.watchWallets().first,
    categories: await money.watchCategories().first,
    transactions: await money.watchTransactions().first,
    budgets: await money.watchBudgets().first,
  );
  _entries = await journal.watchEntries().first;
  await db.close();
}

/// Ketebalan tiap file dibaca dari isi font-nya sendiri.
Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final shotKey = GlobalKey();

  setUpAll(() async {
    await initializeDateFormatting();
    // Di flutter test font default berupa kotak-kotak; muat font asli.
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Poppins-$w.ttf',
    ]);
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ?? 'C:/dev/flutter';
    await _loadFont('MaterialIcons', [
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    // Tombol widget layar utama tidak ada di test.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['home_widget', 'home_widget/updates']) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    await _buildDemoData();
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    Brightness brightness = Brightness.light,
    SettingsRepository? settings,
  }) async {
    tester.view.physicalSize = _size * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalEntriesProvider.overrideWith((ref) => Stream.value(_entries)),
          moneySnapshotProvider.overrideWithValue(AsyncValue.data(_snap)),
          accountProvider.overrideWith(_FakeAccount.new),
          lockProvider.overrideWith(_FakeLock.new),
          homeWidgetSyncProvider.overrideWithValue(null),
          settingsRepositoryProvider.overrideWithValue(settings ?? _FakeSettings()),
        ],
        child: RepaintBoundary(
          key: shotKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(brightness),
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester);
    await tester.runAsync(() async {
      final boundary =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> tapDock(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  /// flutter_test menggambar bayangan tanpa blur; nyalakan blur selama
  /// screenshot, lalu kembalikan sebelum test selesai (dicek framework).
  Future<void> withShadows(Future<void> Function() body) async {
    debugDisableShadows = false;
    try {
      await body();
    } finally {
      debugDisableShadows = true;
    }
  }

  testWidgets('layar utama', (tester) async {
    await withShadows(() async {
      await pumpApp(tester, const HomeShell());
      await shoot(tester, 'hari-ini');
      await tapDock(tester, 'Jurnal');
      await shoot(tester, 'jurnal');
      await tester.tap(find.text('Jalan sore di taman'));
      await settle(tester);
      await shoot(tester, 'catatan-suara');
      await shoot(tester, 'tulis-jurnal');
      Navigator.of(tester.element(find.byType(EntryFormScreen))).pop();
      await settle(tester);
      await tapDock(tester, 'Keuangan');
      await shoot(tester, 'keuangan');
      await tapDock(tester, 'Laporan');
      await shoot(tester, 'laporan');
    });
  });

  testWidgets('mode gelap', (tester) async {
    await withShadows(() async {
      await pumpApp(tester, const HomeShell(), brightness: Brightness.dark);
      await shoot(tester, 'hari-ini-gelap');
    });
  });

  /// Buka layar di atas HomeShell, seperti dari app (ada tombol kembali).
  Future<void> pushOverHome(WidgetTester tester, Widget screen) async {
    await pumpApp(tester, const HomeShell());
    unawaited(
      Navigator.of(tester.element(find.byType(HomeShell)))
          .push(MaterialPageRoute<void>(builder: (_) => screen)),
    );
    await settle(tester);
  }

  testWidgets('pencarian', (tester) async {
    await withShadows(() async {
      await pushOverHome(tester, const SearchScreen());
      await tester.enterText(find.byType(TextField), 'makan');
      await settle(tester);
      // Sembunyikan kursor teks supaya gambar rapi.
      FocusManager.instance.primaryFocus?.unfocus();
      await shoot(tester, 'cari');
    });
  });

  testWidgets('kelola kategori', (tester) async {
    await withShadows(() async {
      await pushOverHome(tester, const CategoriesScreen());
      await shoot(tester, 'kelola-kategori');
    });
  });

  testWidgets('kelola dompet', (tester) async {
    await withShadows(() async {
      await pushOverHome(tester, const WalletsScreen());
      await shoot(tester, 'kelola-dompet');
    });
  });

  testWidgets('mode privasi', (tester) async {
    await withShadows(() async {
      final settings = _FakeSettings();
      await settings.set('hide_amounts', 'true');
      await pumpApp(tester, const HomeShell(), settings: settings);
      await tapDock(tester, 'Keuangan');
      await shoot(tester, 'mode-privasi');
    });
  });

  testWidgets('layar kunci', (tester) async {
    await withShadows(() async {
      await pumpApp(tester, const LockScreen());
      await shoot(tester, 'kunci');
    });
  });
}

/// SVG maskot dimuat secara async: beri waktu nyata, lalu selesaikan animasi.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }
}
