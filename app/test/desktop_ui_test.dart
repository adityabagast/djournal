import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/home_widget_sync.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/data/sync/account_controller.dart';
import 'package:djournal/features/journal/journal_screen.dart';
import 'package:djournal/features/shell/home_shell.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeAccount extends AccountController {
  @override
  AccountState build() => const AccountState(loading: false);

  @override
  Future<void> sync() async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('desktop: HomeShell menampilkan sidebar navigasi rail di layar lebar desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalEntriesProvider.overrideWith((ref) => Stream.value(const [])),
            moneySnapshotProvider.overrideWithValue(
              AsyncValue.data(
                MoneySnapshot(wallets: [], categories: [], transactions: []),
              ),
            ),
            accountProvider.overrideWith(_FakeAccount.new),
            homeWidgetSyncProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const HomeShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi branding dan navigasi rail di sidebar kiri
      expect(find.text('Nyawtat'), findsOneWidget);
      expect(find.text('Ctrl+N'), findsOneWidget);
      expect(find.text('Ctrl+1'), findsOneWidget);
      expect(find.text('Ctrl+2'), findsOneWidget);
      expect(find.text('Ctrl+3'), findsOneWidget);
      expect(find.text('Ctrl+4'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop: JournalScreen menampilkan Master-Detail split-pane', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;

    final now = DateTime.now().toUtc();
    final entry = JournalEntry(
      id: 'entry-1',
      createdAt: now,
      updatedAt: now,
      isDirty: false,
      entryDate: '2026-10-16',
      entryTime: '21:30',
      title: 'Mempersiapkan Rilis Windows Desktop',
      body: 'Adaptasi UI Nyawtat untuk desktop Windows dengan split-pane.',
      mood: 5,
    );

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalEntriesProvider.overrideWith((ref) => Stream.value([entry])),
            moneySnapshotProvider.overrideWithValue(
              AsyncValue.data(
                MoneySnapshot(wallets: [], categories: [], transactions: []),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: JournalScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Di mode split-pane desktop, judul entri tampil di master item dan detail pane (total 2)
      expect(find.text('Mempersiapkan Rilis Windows Desktop'), findsNWidgets(2));
      // Teks isi tampil di master item dan reader pane kanan (total 2)
      expect(
        find.text('Adaptasi UI Nyawtat untuk desktop Windows dengan split-pane.'),
        findsNWidgets(2),
      );
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

