import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/features/money/data/money_repository.dart';
import 'package:djournal/features/money/domain/money_snapshot.dart';
import 'package:djournal/features/money/domain/money_calendar.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortAmount', () {
    test('di bawah seribu ditulis apa adanya', () {
      expect(shortAmount(0), '0');
      expect(shortAmount(500), '500');
    });

    test('ribuan dibulatkan ke rb', () {
      expect(shortAmount(1000), '1rb');
      expect(shortAmount(85000), '85rb');
      expect(shortAmount(22400), '22rb');
      expect(shortAmount(22500), '23rb');
    });

    test('jutaan dibulatkan ke 0,1 jt', () {
      expect(shortAmount(1000000), '1jt');
      expect(shortAmount(1200000), '1,2jt');
      expect(shortAmount(8500000), '8,5jt');
      expect(shortAmount(12000000), '12jt');
    });

    test('tidak pernah menghasilkan 1000rb', () {
      expect(shortAmount(999400), '999rb');
      expect(shortAmount(999500), '1jt');
      expect(shortAmount(999999), '1jt');
    });
  });

  group('dailyTotals', () {
    late AppDatabase db;
    late MoneyRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = MoneyRepository(db);
    });

    tearDown(() => db.close());

    test('menjumlah per tanggal dan mengabaikan transfer', () async {
      await repo.addWallet(name: 'BCA', type: 'bank', openingBalance: 0);
      final wallets = await repo.watchWallets().first;
      final cats = await repo.watchCategories().first;
      final cash = wallets.firstWhere((w) => w.name == 'Tunai');
      final bca = wallets.firstWhere((w) => w.name == 'BCA');
      final food = cats.firstWhere((c) => c.systemKey == 'food');
      final salary = cats.firstWhere((c) => c.systemKey == 'salary');

      Future<void> add(
        String type,
        int amount,
        DateTime at, {
        String? to,
        String? cat,
      }) => repo.saveTransaction(
        type: type,
        amount: amount,
        walletId: bca.id,
        toWalletId: to,
        categoryId: cat,
        note: null,
        occurredAt: at,
      );

      await add('expense', 25000, DateTime(2026, 10, 20, 8), cat: food.id);
      await add('expense', 38000, DateTime(2026, 10, 20, 12), cat: food.id);
      await add('income', 8500000, DateTime(2026, 10, 20, 9), cat: salary.id);
      await add('transfer', 300000, DateTime(2026, 10, 21, 8), to: cash.id);
      await add('expense', 10000, DateTime(2026, 9, 30, 8), cat: food.id);

      final snap = MoneySnapshot(
        wallets: wallets,
        categories: cats,
        transactions: await repo.watchTransactions().first,
      );
      final totals = dailyTotals(snap, '2026-10');

      expect(totals.keys, ['2026-10-20']);
      expect(totals['2026-10-20']!.expense, 63000);
      expect(totals['2026-10-20']!.income, 8500000);
    });
  });
}
