import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/features/report/report_charts.dart';
import 'package:djournal/features/report/report_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';

void main() {
  final catFood = Category(
    id: 'cat-food',
    name: 'Makanan',
    kind: 'expense',
    color: '#E06D53',
    icon: 'makan',
    sortOrder: 1,
    systemKey: 'food',
    isArchived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isDirty: false,
  );

  final catTransport = Category(
    id: 'cat-transport',
    name: 'Transport',
    kind: 'expense',
    color: '#4A90E2',
    icon: 'mobil',
    sortOrder: 2,
    systemKey: 'transport',
    isArchived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isDirty: false,
  );

  final walletCash = Wallet(
    id: 'w-cash',
    name: 'Tunai',
    type: 'cash',
    openingBalance: 1000000,
    color: '#1F5F4E',
    sortOrder: 1,
    isArchived: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isDirty: false,
  );

  Widget wrap(Widget child, {List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('ExpenseDonutChart', () {
    testWidgets('renders items with percentages and respects hideAmounts', (tester) async {
      final items = [
        CategorySpend(category: catFood, spent: 300000, percentage: 75.0),
        CategorySpend(category: catTransport, spent: 100000, percentage: 25.0),
      ];

      await tester.pumpWidget(
        wrap(
          ExpenseDonutChart(
            items: items,
            totalSpent: 400000,
            hideAmounts: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa persentase dan label
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('25.0%'), findsOneWidget);
      expect(find.text('Rp 300.000'), findsOneWidget);
      expect(find.text('Rp 100.000'), findsOneWidget);
      expect(find.text('Rp 400.000'), findsOneWidget);

      // Cek privacy mode
      await tester.pumpWidget(
        wrap(
          ExpenseDonutChart(
            items: items,
            totalSpent: 400000,
            hideAmounts: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rp 300.000'), findsNothing);
      expect(find.text('Rp •••••'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap on category selects and updates center info', (tester) async {
      String? selectedId;
      final items = [
        CategorySpend(category: catFood, spent: 300000, percentage: 75.0),
        CategorySpend(category: catTransport, spent: 100000, percentage: 25.0),
      ];

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return ExpenseDonutChart(
                items: items,
                totalSpent: 400000,
                hideAmounts: false,
                selectedCategoryId: selectedId,
                onSelectCategory: (id) => setState(() => selectedId = id),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Transport row
      await tester.tap(find.text('25.0%'));
      await tester.pumpAndSettle();

      expect(selectedId, 'cat-transport');
    });
  });

  group('WeeklyBarChart', () {
    testWidgets('calculates and renders weekly expenses', (tester) async {
      final now = DateTime(2026, 10, 14);
      final txs = [
        MoneyTx(
          id: 'tx1',
          type: 'expense',
          amount: 50000,
          walletId: 'w-cash',
          categoryId: 'cat-food',
          occurredAt: DateTime(2026, 10, 3, 10, 0),
          localDate: '2026-10-03',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDirty: false,
        ),
        MoneyTx(
          id: 'tx2',
          type: 'expense',
          amount: 150000,
          walletId: 'w-cash',
          categoryId: 'cat-transport',
          occurredAt: DateTime(2026, 10, 10, 14, 0),
          localDate: '2026-10-10',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDirty: false,
        ),
      ];

      await tester.pumpWidget(
        wrap(
          WeeklyBarChart(
            monthTransactions: txs,
            month: now,
            hideAmounts: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('M1'), findsOneWidget);
      expect(find.text('M2'), findsOneWidget);
      expect(find.text('M3'), findsOneWidget);
      expect(find.text('M4'), findsOneWidget);
      expect(find.text('M5'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsAtLeastNWidgets(1));
    });
  });

  group('ReportScreen Integration', () {
    testWidgets('renders chart card and switches segments', (tester) async {
      final snap = MoneySnapshot(
        wallets: [walletCash],
        categories: [catFood, catTransport],
        transactions: [
          MoneyTx(
            id: 'tx-1',
            type: 'expense',
            amount: 250000,
            walletId: 'w-cash',
            categoryId: 'cat-food',
            occurredAt: DateTime.now(),
            localDate: '2026-10-14',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isDirty: false,
          ),
        ],
        budgets: const [],
      );

      await tester.pumpWidget(
        wrap(
          const ReportScreen(),
          overrides: [
            moneySnapshotProvider.overrideWithValue(AsyncValue.data(snap)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Cek judul Analisis Pengeluaran dan tombol segmen
      expect(find.text('Analisis Pengeluaran'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Mingguan'), findsOneWidget);

      // Cek chart donut muncul
      expect(find.byType(ExpenseDonutChart), findsOneWidget);

      // Tap Mingguan segmen
      await tester.tap(find.text('Mingguan'));
      await tester.pumpAndSettle();

      expect(find.byType(WeeklyBarChart), findsOneWidget);

      // Cek navigasi bulan sebelumnya
      final prevBtn = find.byTooltip('Bulan sebelumnya');
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      // Tombol "Bulan ini" muncul saat mundur ke bulan lalu
      expect(find.text('Bulan ini'), findsOneWidget);
    });
  });
}

