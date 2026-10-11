import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/features/money/wallets_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Wallet _wallet(String id, String name, int opening, {bool archived = false}) =>
    Wallet(
      id: id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isDirty: false,
      name: name,
      type: 'bank',
      openingBalance: opening,
      sortOrder: 0,
      isArchived: archived,
    );

void main() {
  testWidgets('dompet aktif dan arsip dipisah, total hanya yang aktif', (
    tester,
  ) async {
    final snap = MoneySnapshot(
      wallets: [
        _wallet('a', 'Mandiri', 50000),
        _wallet('b', 'Krom bank', -2500),
        _wallet('c', 'BCA', 36588, archived: true),
      ],
      categories: const [],
      transactions: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneySnapshotProvider.overrideWithValue(AsyncValue.data(snap)),
        ],
        child: MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const WalletsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total saldo 2 dompet aktif'), findsOneWidget);
    expect(find.text('Rp 47.500'), findsOneWidget);
    // Saldo minus tetap bertanda minus.
    expect(find.text('−Rp 2.500'), findsOneWidget);
    expect(find.text('ARSIP (1)'), findsOneWidget);
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('Keluarkan'), findsOneWidget);

    // Bagian arsip bisa dilipat.
    await tester.tap(find.text('ARSIP (1)'));
    await tester.pumpAndSettle();
    expect(find.text('BCA'), findsNothing);
  });
}
