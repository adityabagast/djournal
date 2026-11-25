import 'package:djournal/features/account/data/backend.dart';
import 'package:djournal/features/account/presentation/account_card.dart';
import 'package:djournal/features/account/presentation/account_screen.dart';
import 'package:djournal/features/account/presentation/sign_in_screen.dart';
import 'package:djournal/features/account/providers/account_controller.dart';
import 'package:djournal/features/backup/data/google_drive_service.dart';
import 'package:djournal/features/backup/presentation/backup_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _drive = GoogleDriveInfo(
  email: 'nyaw@contoh.id',
  displayName: 'Nyaw Contoh',
);
const _noServer = AccountState(loading: false);
const _server = AccountState(loading: false, email: 'server@contoh.id');

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  Future<(_FakeAccount, _FakeDrive)> pump(
    WidgetTester tester, {
    AccountState account = _noServer,
    GoogleDriveInfo drive = const GoogleDriveInfo(),
    bool unsynced = false,
    Widget child = const Scaffold(
      body: SingleChildScrollView(child: AccountCard()),
    ),
  }) async {
    final a = _FakeAccount(account, unsynced);
    final d = _FakeDrive(drive);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith(() => a),
          googleDriveProvider.overrideWith(() => d),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (a, d);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('ringkasan akun di Pengaturan', () {
    testWidgets('tamu: ajakan masuk ke server', (tester) async {
      await pump(tester);
      expect(find.text('Mode Tamu (Offline)'), findsOneWidget);
      await tap(tester, 'Masuk ke server');
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('Drive saja: tetap bisa masuk ke server', (tester) async {
      await pump(tester, drive: _drive);
      expect(find.text('Nyaw Contoh'), findsOneWidget);
      expect(find.text('nyaw@contoh.id'), findsOneWidget);
      expect(find.text('Belum masuk, data belum tersinkron'), findsOneWidget);
      await tap(tester, 'Masuk ke server');
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('keduanya: status tampil, tanpa tombol keluar', (tester) async {
      await pump(
        tester,
        account: _server.copyWith(
          lastSyncAt: () => DateTime(2026, 11, 25, 14, 32),
        ),
        drive: _drive,
      );
      expect(find.text('nyaw@contoh.id • server@contoh.id'), findsOneWidget);
      expect(
        find.text('Sinkron otomatis · terakhir 25 Nov, 14:32'),
        findsOneWidget,
      );
      expect(find.textContaining('Keluar'), findsNothing);
      expect(find.text('Masuk ke server'), findsNothing);

      await tap(tester, 'Nyaw Contoh');
      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('sesi habis: masuk lagi', (tester) async {
      await pump(
        tester,
        account: _server.copyWith(error: () => ApiError.sessionExpired),
        drive: _drive,
      );
      await tap(tester, 'Masuk ke server');
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('halaman Akun', () {
    testWidgets('sinkron manual dan hubungkan Drive', (tester) async {
      final (a, d) = await pump(
        tester,
        account: _server,
        child: const AccountScreen(),
      );
      await tap(tester, 'Sinkronkan');
      expect(a.syncs, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tap(tester, 'Hubungkan');
      expect(d.signIns, 1);
    });

    testWidgets('sedang sinkron: tombol nonaktif', (tester) async {
      final (a, _) = await pump(
        tester,
        account: _server.copyWith(syncing: true),
        child: const AccountScreen(),
      );
      await tap(tester, 'Sinkronkan');
      expect(a.syncs, 0);
    });

    testWidgets('offline: coba lagi', (tester) async {
      final (a, _) = await pump(
        tester,
        account: _server.copyWith(error: () => ApiError.network),
        child: const AccountScreen(),
      );
      await tap(tester, 'Coba lagi');
      expect(a.syncs, 1);
    });

    testWidgets('putuskan Drive: batal, lalu jadi, server tidak tersentuh', (
      tester,
    ) async {
      final (a, d) = await pump(
        tester,
        account: _server,
        drive: _drive,
        child: const AccountScreen(),
      );
      await tap(tester, 'Putuskan Google Drive');
      await tap(tester, 'Tetap terhubung');
      expect(d.signOuts, 0);
      await tap(tester, 'Putuskan Google Drive');
      await tap(tester, 'Putuskan');
      expect(d.signOuts, 1);
      expect(a.signOuts, 0);
    });

    testWidgets('keluar server: tanpa centang tidak terjadi apa-apa', (
      tester,
    ) async {
      final (a, d) = await pump(
        tester,
        account: _server,
        drive: _drive,
        child: const AccountScreen(),
      );
      await tap(tester, 'Keluar dari server');
      expect(find.textContaining('tidak ada di server'), findsOneWidget);
      expect(find.textContaining('belum tersinkron'), findsNothing);
      await tap(tester, 'Keluar dan hapus data');
      expect(a.signOuts, 0);
      await tap(tester, 'Batal');
      expect(a.signOuts, 0);
      expect(d.signOuts, 0);
    });

    testWidgets('keluar server: cadangkan dulu membuka halaman cadangan', (
      tester,
    ) async {
      final (a, _) = await pump(
        tester,
        account: _server,
        drive: _drive,
        child: const AccountScreen(),
      );
      await tap(tester, 'Keluar dari server');
      await tap(tester, 'Cadangkan dulu');
      expect(find.byType(BackupScreen), findsOneWidget);
      expect(a.signOuts, 0);
    });

    testWidgets('keluar server: setelah dicentang, Drive tetap terhubung', (
      tester,
    ) async {
      final (a, d) = await pump(
        tester,
        account: _server,
        drive: _drive,
        unsynced: true,
        child: const AccountScreen(),
      );
      await tap(tester, 'Keluar dari server');
      expect(
        find.textContaining('perubahan yang belum tersinkron'),
        findsOneWidget,
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tap(tester, 'Keluar dan hapus data');
      expect(a.signOuts, 1);
      expect(d.signOuts, 0);
    });
  });

  group('layar masuk', () {
    testWidgets('Drive terhubung: tanpa tombol Google', (tester) async {
      await pump(tester, drive: _drive, child: const SignInScreen());
      expect(find.text('Masuk ke server'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsNothing);
      expect(find.textContaining('Drive tetap terhubung'), findsOneWidget);
      expect(find.textContaining('Dikirim ke server'), findsOneWidget);
    });

    testWidgets('tamu: tombol Google ada', (tester) async {
      await pump(tester, child: const SignInScreen());
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.textContaining('Drive tetap terhubung'), findsNothing);
    });
  });
}

class _FakeAccount extends AccountController {
  _FakeAccount(this._initial, this._unsynced);
  final AccountState _initial;
  final bool _unsynced;
  int syncs = 0;
  int signOuts = 0;

  @override
  AccountState build() => _initial;

  @override
  Future<void> sync() async => syncs++;

  @override
  Future<bool> hasUnsyncedChanges() async => _unsynced;

  @override
  Future<void> signOut() async => signOuts++;
}

class _FakeDrive extends GoogleDriveController {
  _FakeDrive(this._initial);
  final GoogleDriveInfo _initial;
  int signIns = 0;
  int signOuts = 0;

  @override
  GoogleDriveInfo build() => _initial;

  @override
  Future<void> signIn() async => signIns++;

  @override
  Future<void> signOut() async => signOuts++;
}
