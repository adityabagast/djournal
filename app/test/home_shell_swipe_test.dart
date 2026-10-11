import 'package:djournal/data/home_widget_sync.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/data/sync/account_controller.dart';
import 'package:djournal/features/shell/home_shell.dart';
import 'package:djournal/features/today/today_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Kanal widget layar utama tidak ada di test.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['home_widget', 'home_widget/updates']) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
  });

  testWidgets('tab bisa digeser dan tetap hidup di luar layar', (tester) async {
    // Widget test dengan database drift asli bisa macet; pakai data kosong.
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
    final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(pages.page, 0);

    // Geser ke kiri = tab berikutnya (Jurnal).
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(pages.page, 1);

    // Tap dock tetap bisa, dan langsung lompat ke Laporan.
    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();
    expect(pages.page, 3);

    // Hari Ini tidak dibuang walau sudah jauh di luar layar.
    expect(find.byType(TodayScreen, skipOffstage: false), findsOneWidget);

    // Geser ke kanan = tab sebelumnya (Keuangan).
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(pages.page, 2);
  });
}
