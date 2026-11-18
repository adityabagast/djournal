import 'package:djournal/core/format.dart';
import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/features/money/domain/money_snapshot.dart';
import 'package:djournal/features/money/presentation/money_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MoneyTx _tx(String id, String type, int amount, DateTime at) => MoneyTx(
  id: id,
  type: type,
  amount: amount,
  walletId: 'w',
  note: 'tx-$id',
  occurredAt: at,
  localDate: toLocalDate(at),
  createdAt: at,
  updatedAt: at,
  isDirty: false,
);

void main() {
  testWidgets('kalender menampilkan total harian dan memfilter per tanggal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final day1 = DateTime(now.year, now.month, 1, 9);
    final prev = DateTime(now.year, now.month, 0, 9); // Bulan lalu.
    final snap = MoneySnapshot(
      wallets: [
        Wallet(
          id: 'w',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isDirty: false,
          name: 'Tunai',
          type: 'cash',
          openingBalance: 0,
          sortOrder: 0,
          isArchived: false,
        ),
      ],
      categories: const [],
      transactions: [
        _tx('a', 'expense', 85000, day1),
        _tx('b', 'income', 1200000, day1),
        _tx('c', 'expense', 40000, prev),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneySnapshotProvider.overrideWithValue(AsyncValue.data(snap)),
          hideAmountsProvider.overrideWithValue(const AsyncValue.data(false)),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: MoneyScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sel tanggal 1: total ringkas keluar dan masuk.
    expect(find.text('-85rb'), findsOneWidget);
    expect(find.text('+1,2jt'), findsOneWidget);
    // Tanpa pilihan: semua hari tampil, termasuk bulan lalu.
    expect(find.text('tx-a'), findsOneWidget);
    expect(find.text('tx-c'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('cal-${toLocalDate(day1)}')));
    await tester.pumpAndSettle();
    expect(find.text('tx-a'), findsOneWidget);
    expect(find.text('tx-c'), findsNothing);
    expect(find.text('Rp 85.000'), findsWidgets);

    await tester.tap(find.text('Tampilkan semua hari'));
    await tester.pumpAndSettle();
    expect(find.text('tx-c'), findsOneWidget);

    // Bulan lalu: tanggal bulan ini tidak ikut di daftar.
    await tester.tap(find.byTooltip('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text('-40rb'), findsOneWidget);
    expect(find.text('tx-a'), findsNothing);
    expect(find.text('tx-c'), findsOneWidget);
  });
}
