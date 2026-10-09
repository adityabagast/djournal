import 'package:djournal/core/format.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/features/journal/journal_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry _entry(String id, String date, String title) {
  final now = DateTime.now().toUtc();
  return JournalEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    isDirty: false,
    entryDate: date,
    title: title,
  );
}

void main() {
  testWidgets('tap tanggal di strip minggu memfilter entri jurnal', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      _entry('a', toLocalDate(now), 'Entri hari ini'),
      _entry(
        'b',
        toLocalDate(now.subtract(const Duration(days: 20))),
        'Entri lama',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalEntriesProvider.overrideWith((ref) => Stream.value(entries)),
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

    expect(find.text('Entri hari ini'), findsOneWidget);
    expect(find.text('Entri lama'), findsOneWidget);

    await tester.tap(find.text('${now.day}'));
    await tester.pumpAndSettle();
    expect(find.text('Entri hari ini'), findsOneWidget);
    expect(find.text('Entri lama'), findsNothing);
    expect(find.text('Tampilkan semua'), findsOneWidget);

    // Tap lagi tanggal yang sama = lepas filter.
    await tester.tap(find.text('${now.day}'));
    await tester.pumpAndSettle();
    expect(find.text('Entri lama'), findsOneWidget);
    expect(find.text('Tampilkan semua'), findsNothing);
  });
}
