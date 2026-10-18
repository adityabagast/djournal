import 'package:djournal/data/google_drive_service.dart';
import 'package:djournal/data/sync/account_controller.dart';
import 'package:djournal/features/account/account_card.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, List<dynamic> overrides) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('Mode Tamu tampil jika belum ada akun yang login', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AccountCard(),
        [
          accountProvider.overrideWith(
            () => _FakeAccountController(
              const AccountState(loading: false, email: null),
            ),
          ),
          googleDriveProvider.overrideWith(
            () => _FakeGoogleDriveController(const GoogleDriveInfo()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mode Tamu (Offline)'), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);
  });

  testWidgets('Kartu Akun menampilkan profil Google saat Google Drive terhubung', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AccountCard(),
        [
          accountProvider.overrideWith(
            () => _FakeAccountController(
              const AccountState(loading: false, email: null),
            ),
          ),
          googleDriveProvider.overrideWith(
            () => _FakeGoogleDriveController(
              const GoogleDriveInfo(
                email: 'dirtybubble02@gmail.com',
                displayName: 'dirtybubble02',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('dirtybubble02'), findsOneWidget);
    expect(find.text('dirtybubble02@gmail.com'), findsOneWidget);
    expect(find.text('Google Drive Terhubung'), findsOneWidget);
    expect(find.text('Cadangkan ke Drive'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('Kartu Akun menampilkan Server Nyawtat saat server terhubung', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AccountCard(),
        [
          accountProvider.overrideWith(
            () => _FakeAccountController(
              const AccountState(loading: false, email: 'user@nyawtat.id'),
            ),
          ),
          googleDriveProvider.overrideWith(
            () => _FakeGoogleDriveController(const GoogleDriveInfo()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('user@nyawtat.id'), findsOneWidget);
    expect(find.text('Server Nyawtat Terhubung'), findsOneWidget);
  });

  testWidgets('Kartu Akun menampilkan kedua badge jika Google dan Server aktif', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AccountCard(),
        [
          accountProvider.overrideWith(
            () => _FakeAccountController(
              const AccountState(loading: false, email: 'server@nyawtat.id'),
            ),
          ),
          googleDriveProvider.overrideWith(
            () => _FakeGoogleDriveController(
              const GoogleDriveInfo(
                email: 'google@gmail.com',
                displayName: 'Google User',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google Drive Terhubung'), findsOneWidget);
    expect(find.text('Server Nyawtat Terhubung'), findsOneWidget);
  });
}

class _FakeAccountController extends AccountController {
  _FakeAccountController(this._initial);
  final AccountState _initial;

  @override
  AccountState build() => _initial;
}

class _FakeGoogleDriveController extends GoogleDriveController {
  _FakeGoogleDriveController(this._initial);
  final GoogleDriveInfo _initial;

  @override
  GoogleDriveInfo build() => _initial;
}

