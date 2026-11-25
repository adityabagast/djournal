import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/core/storage/settings_repository.dart';
import 'package:djournal/features/account/providers/account_controller.dart';
import 'package:djournal/features/backup/data/backup_service.dart';
import 'package:djournal/features/backup/data/google_drive_service.dart';
import 'package:djournal/features/lock/providers/lock_controller.dart';
import 'package:djournal/features/settings/presentation/settings_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Pengaturan hanya mengubah tampilan: memakainya tidak boleh menghapus data
/// atau mengeluarkan user dari akunnya.
void main() {
  setUpAll(() => initializeDateFormatting('id'));

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addEntry(String id, String body, DateTime at) => db
      .into(db.journalEntries)
      .insert(
        JournalEntriesCompanion.insert(
          id: id,
          createdAt: at,
          updatedAt: at,
          entryDate: '2026-11-25',
          body: Value(body),
        ),
      );

  Future<String?> accountEmail() async =>
      (await (db.select(db.appSettings)
                ..where((s) => s.key.equals(accountEmailKey)))
              .getSingleOrNull())
          ?.value;

  testWidgets('membuka semua menu tidak menghapus data atau login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final account = _FakeAccount();
    final drive = _FakeDrive();
    late int wallets, categories;
    await tester.runAsync(() async {
      await addEntry('e1', 'Catatan contoh', DateTime.utc(2026, 11, 25));
      await SettingsRepository(db).set(accountEmailKey, 'server@contoh.id');
      wallets = (await db.select(db.wallets).get()).length;
      categories = (await db.select(db.categories).get()).length;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(_FakeSettings()),
          accountProvider.overrideWith(() => account),
          googleDriveProvider.overrideWith(() => drive),
          themeModeProvider.overrideWith((ref) => Stream.value(ThemeMode.light)),
          accentIdProvider.overrideWith((ref) => Stream.value('sage')),
          accentRecentProvider.overrideWith((ref) => Stream.value(const [])),
          hideAmountsProvider.overrideWith((ref) => Stream.value(false)),
          lockProvider.overrideWith(_FakeLock.new),
          appVersionProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Nyawtat',
              packageName: 'dev.nyawtat.app',
              version: '0.19.0',
              buildNumber: '25',
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final menu in [
      'Nyaw Contoh',
      'Tampilan & bahasa',
      'Keamanan',
      'Keuangan',
      'Cadangan & pemulihan',
      'Versi & update',
      'Kirim masukan',
    ]) {
      await tester.tap(find.text(menu));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget, reason: menu);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget, reason: menu);
    }

    expect(account.signOuts, 0);
    expect(drive.signOuts, 0);
    await tester.runAsync(() async {
      expect(await accountEmail(), 'server@contoh.id');
      expect(await db.select(db.journalEntries).get(), hasLength(1));
      expect(await db.select(db.wallets).get(), hasLength(wallets));
      expect(await db.select(db.categories).get(), hasLength(categories));
    });
  });

  test('pulihkan: catatan lebih baru tidak ditimpa, akun tetap masuk', () async {
    await SettingsRepository(db).set(accountEmailKey, 'server@contoh.id');
    await addEntry('e1', 'Versi lama', DateTime.utc(2026, 11, 20));
    final backup = await BackupService(db).exportJson();

    await (db.update(db.journalEntries)..where((e) => e.id.equals('e1'))).write(
      JournalEntriesCompanion(
        body: const Value('Versi baru di HP'),
        updatedAt: Value(DateTime.utc(2026, 11, 25)),
      ),
    );
    await addEntry('e2', 'Hanya ada di HP', DateTime.utc(2026, 11, 25));

    await BackupService(db).importJson(backup);

    final bodies = {
      for (final e in await db.select(db.journalEntries).get()) e.id: e.body,
    };
    expect(bodies, {'e1': 'Versi baru di HP', 'e2': 'Hanya ada di HP'});
    expect(await accountEmail(), 'server@contoh.id');
  });
}

class _FakeAccount extends AccountController {
  int signOuts = 0;

  @override
  AccountState build() =>
      const AccountState(loading: false, email: 'server@contoh.id');

  @override
  Future<void> signOut() async => signOuts++;
}

class _FakeDrive extends GoogleDriveController {
  int signOuts = 0;

  @override
  GoogleDriveInfo build() => const GoogleDriveInfo(
    email: 'nyaw@contoh.id',
    displayName: 'Nyaw Contoh',
  );

  @override
  Future<void> signOut() async => signOuts++;
}

class _FakeLock extends LockController {
  @override
  LockState build() => const LockState(loading: false);
}

class _FakeSettings implements SettingsRepository {
  @override
  Stream<String?> watch(String key) => Stream.value(null);

  @override
  Future<void> set(String key, String value) async {}

  @override
  Future<void> remove(String key) async => fail('setelan $key dihapus');
}
