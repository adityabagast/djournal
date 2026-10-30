import 'dart:convert';

import 'package:djournal/data/backup_service.dart';
import 'package:djournal/data/bill_repository.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/wishlist_repository.dart';
import 'package:djournal/domain/models/backup_period.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase a;
  late AppDatabase b;

  setUp(() {
    a = AppDatabase(NativeDatabase.memory());
    b = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  test(
    'ekspor lalu impor ke HP baru: data pindah, bawaan tidak dobel',
    () async {
      final moneyA = MoneyRepository(a);
      await moneyA.addWallet(name: 'BCA', type: 'bank', openingBalance: 500000);
      final walletsA = await moneyA.watchWallets().first;
      final bca = walletsA.firstWhere((w) => w.name == 'BCA');
      final food = (await moneyA.watchCategories().first).firstWhere(
        (c) => c.systemKey == 'food',
      );
      await moneyA.saveTransaction(
        type: 'expense',
        amount: 25000,
        walletId: bca.id,
        categoryId: food.id,
        note: 'Kopi, "susu"',
        occurredAt: DateTime(2026, 10, 8, 7, 45),
      );
      await moneyA.setBudget(
        categoryId: food.id,
        startMonth: '2026-10',
        amount: 1000000,
      );
      await JournalRepository(a).saveEntry(
        entryDate: '2026-10-08',
        entryTime: '07:30',
        mood: 4,
        title: 'Sarapan',
        body: null,
        tags: ['pagi'],
      );

      final json = await BackupService(a).exportJson();
      expect(jsonDecode(json)['format'], 'djournal-backup');

      // HP baru dengan data bawaannya sendiri (id berbeda).
      final moneyB = MoneyRepository(b);
      final result = await BackupService(b).importJson(json);
      expect(result.imported, greaterThan(0));

      final walletsB = await moneyB.watchWallets().first;
      final catsB = await moneyB.watchCategories().first;
      expect(
        walletsB.map((w) => w.id).toSet(),
        walletsA.map((w) => w.id).toSet(),
        reason: 'dompet Tunai bawaan HP baru digabung ke milik backup',
      );
      expect(catsB, hasLength(9), reason: 'kategori bawaan tidak dobel');
      expect(catsB.firstWhere((c) => c.systemKey == 'food').id, food.id);

      final tx = (await moneyB.watchTransactions().first).single;
      expect(tx.note, 'Kopi, "susu"');
      expect(
        tx.isDirty,
        isTrue,
        reason: 'hasil impor harus ikut terkirim ke server',
      );
      expect((await moneyB.watchBudgets().first).single.amount, 1000000);
      final entry = (await JournalRepository(b).watchEntries().first).single;
      expect(entryTags(entry), ['pagi']);

      // Impor file yang sama lagi: tidak ada yang berubah.
      final again = await BackupService(b).importJson(json);
      expect(again.imported, 0);
      expect(await moneyB.watchTransactions().first, hasLength(1));
    },
  );

  test('data di HP yang lebih baru tidak ditimpa backup lama', () async {
    final money = MoneyRepository(a);
    final wallet = (await money.watchWallets().first).single;
    final food = (await money.watchCategories().first).firstWhere(
      (c) => c.systemKey == 'food',
    );
    await money.saveTransaction(
      type: 'expense',
      amount: 10000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'lama',
      occurredAt: DateTime(2026, 10, 8),
    );
    final backup = await BackupService(a).exportJson();

    final tx = (await money.watchTransactions().first).single;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await money.saveTransaction(
      id: tx.id,
      type: 'expense',
      amount: 12000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'baru',
      occurredAt: DateTime(2026, 10, 8),
    );

    await BackupService(a).importJson(backup);
    expect((await money.watchTransactions().first).single.note, 'baru');
  });

  test('file yang bukan backup ditolak', () async {
    final service = BackupService(a);
    expect(
      () => service.importJson('bukan json'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => service.importJson('{"format":"lain","version":1}'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => service.importJson('{"format":"djournal-backup","version":99}'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('exportJson dengan BackupPeriod hanya memfilter transaksi & jurnal sesuai rentang', () async {
    final money = MoneyRepository(a);
    final journal = JournalRepository(a);
    final wallet = (await money.watchWallets().first).single;
    final food = (await money.watchCategories().first).firstWhere(
      (c) => c.systemKey == 'food',
    );

    // Transaksi Oktober 2026
    await money.saveTransaction(
      type: 'expense',
      amount: 20000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'Tx Oktober',
      occurredAt: DateTime(2026, 10, 10),
    );

    // Transaksi Januari 2026
    await money.saveTransaction(
      type: 'expense',
      amount: 50000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'Tx Januari',
      occurredAt: DateTime(2026, 1, 15),
    );

    // Jurnal Oktober 2026
    await journal.saveEntry(
      entryDate: '2026-10-10',
      entryTime: '08:00',
      mood: 4,
      title: 'Jurnal Oktober',
      body: 'Cerita',
      tags: [],
    );

    // Jurnal Januari 2026
    await journal.saveEntry(
      entryDate: '2026-01-15',
      entryTime: '09:00',
      mood: 3,
      title: 'Jurnal Januari',
      body: 'Cerita',
      tags: [],
    );

    // Ekspor dengan filter bulan Oktober 2026
    final json = await BackupService(a).exportJson(
      period: BackupPeriod.thisMonth(DateTime(2026, 10, 1)),
    );
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    final txList = decoded['transactions'] as List;
    final entryList = decoded['journalEntries'] as List;

    expect(txList.length, 1);
    expect(txList.first['note'], 'Tx Oktober');

    expect(entryList.length, 1);
    expect(entryList.first['title'], 'Jurnal Oktober');

    // Wallets dan Categories tetap utuh untuk integritas data
    expect((decoded['wallets'] as List).isNotEmpty, isTrue);
    expect((decoded['categories'] as List).isNotEmpty, isTrue);
  });

  test('wishlist dan tagihan ikut dicadangkan dan dipulihkan', () async {
    final walletA = (await MoneyRepository(a).watchWallets().first).first;
    final wishId = await WishlistRepository(a).createWishlist(
      title: 'Laptop',
      targetAmount: 12000000,
      targetMonths: 12,
      walletId: walletA.id,
    );
    await WishlistRepository(a).deposit(wishlistId: wishId, amount: 1000000);
    await BillRepository(a).createBill(
      title: 'Wi-Fi',
      amount: 350000,
      dueDate: '2026-11-05',
      repeatInterval: 'monthly',
      walletId: walletA.id,
    );

    final json = await BackupService(a).exportJson(
      period: BackupPeriod.thisMonth(DateTime(2026, 10, 1)),
    );
    final result = await BackupService(b).importJson(json);
    expect(result.imported, greaterThan(0));

    final wishes = await b.select(b.wishlists).get();
    expect(wishes.single.title, 'Laptop');
    expect(wishes.single.savedAmount, 1000000);
    expect(wishes.single.isDirty, isTrue);
    final bills = await b.select(b.bills).get();
    expect(bills.single.title, 'Wi-Fi');
    expect(bills.single.dueDate, '2026-11-05');
    expect(bills.single.repeatInterval, 'monthly');

    // Dompet "Tunai" bawaan HP b digabung ke milik file: rujukan ikut.
    final walletsB = await MoneyRepository(b).watchWallets().first;
    expect(walletsB.map((w) => w.id), contains(bills.single.walletId));
    expect(walletsB.map((w) => w.id), contains(wishes.single.walletId));
  });

  test('file backup lama tanpa wishlist & tagihan tetap bisa diimpor', () async {
    final json = jsonDecode(await BackupService(a).exportJson())
        as Map<String, dynamic>
      ..remove('wishlists')
      ..remove('bills');
    await BackupService(b).importJson(jsonEncode(json));
    expect(await b.select(b.bills).get(), isEmpty);
  });
}
