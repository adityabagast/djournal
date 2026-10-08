import 'dart:convert';

import 'package:djournal/data/backup_service.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
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
}
