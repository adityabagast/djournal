import 'package:djournal/core/format.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/features/today/today_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('timeline Hari Ini diurutkan descending (jam terbaru di atas)', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = toLocalDate(now);

    final entries = [
      JournalEntry(
        id: 'j1',
        createdAt: DateTime(now.year, now.month, now.day, 8, 0),
        updatedAt: DateTime(now.year, now.month, now.day, 8, 0),
        isDirty: false,
        entryDate: today,
        entryTime: '08:00',
        title: 'Jurnal Pagi',
      ),
      JournalEntry(
        id: 'j2',
        createdAt: DateTime(now.year, now.month, now.day, 20, 0),
        updatedAt: DateTime(now.year, now.month, now.day, 20, 0),
        isDirty: false,
        entryDate: today,
        entryTime: '20:00',
        title: 'Jurnal Malam',
      ),
    ];

    final wallet = Wallet(
      id: 'w1',
      createdAt: now,
      updatedAt: now,
      isDirty: false,
      name: 'Dompet Utama',
      type: 'cash',
      openingBalance: 100000,
      sortOrder: 0,
      isArchived: false,
    );

    final tx = MoneyTx(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      isDirty: false,
      localDate: today,
      type: 'expense',
      amount: 15000,
      walletId: 'w1',
      note: 'Makan Siang',
      occurredAt: DateTime(now.year, now.month, now.day, 12, 30),
    );

    final snap = MoneySnapshot(
      wallets: [wallet],
      categories: const [],
      transactions: [tx],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalEntriesProvider.overrideWith((ref) => Stream.value(entries)),
          moneySnapshotProvider.overrideWithValue(AsyncValue.data(snap)),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi semua muncul di timeline
    expect(find.text('Jurnal Malam'), findsOneWidget); // 20:00
    expect(find.text('Makan Siang'), findsOneWidget);  // 12:30
    expect(find.text('Jurnal Pagi'), findsOneWidget);   // 08:00

    // Urutan posisi vertikal (Y coordinate):
    // 20:00 (Jurnal Malam) harus paling atas (Y terkecil)
    // 12:30 (Makan Siang) di tengah
    // 08:00 (Jurnal Pagi) paling bawah (Y terbesar)
    final malamY = tester.getTopLeft(find.text('Jurnal Malam')).dy;
    final siangY = tester.getTopLeft(find.text('Makan Siang')).dy;
    final pagiY = tester.getTopLeft(find.text('Jurnal Pagi')).dy;

    expect(malamY, lessThan(siangY));
    expect(siangY, lessThan(pagiY));
  });
}
