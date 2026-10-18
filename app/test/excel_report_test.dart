import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/excel_report.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/domain/models/backup_period.dart';
import 'package:djournal/l10n/app_localizations_id.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('laporan Excel berisi 4 sheet dengan data yang benar', () async {
    final money = MoneyRepository(db);
    final journal = JournalRepository(db);
    final wallet = (await money.watchWallets().first).single;
    final food = (await money.watchCategories().first).firstWhere(
      (c) => c.systemKey == 'food',
    );
    await money.saveTransaction(
      type: 'expense',
      amount: 25000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'Kopi susu',
      occurredAt: DateTime(2026, 10, 8, 7, 45),
    );
    await money.setBudget(
      categoryId: food.id,
      startMonth: '2026-10',
      amount: 1000000,
    );
    await journal.saveEntry(
      entryDate: '2026-10-08',
      entryTime: '07:30',
      mood: 4,
      title: 'Sarapan',
      body: 'Nasi uduk',
      tags: ['pagi', 'kantor'],
    );

    final snap = MoneySnapshot(
      wallets: await money.watchWallets().first,
      categories: await money.watchCategories().first,
      transactions: await money.watchTransactions().first,
      budgets: await money.watchBudgets().first,
    );
    final bytes = buildExcelReport(
      l: AppLocalizationsId(),
      money: snap,
      entries: await journal.watchEntries().first,
      now: DateTime(2026, 10, 8),
    );

    // Baca balik file yang dihasilkan.
    final excel = Excel.decodeBytes(bytes);
    expect(excel.tables.keys.toSet(), {
      'Transaksi',
      'Jurnal',
      'Dompet',
      'Budget',
    }, reason: 'sheet bawaan "Sheet1" sudah dibuang');

    final tx = excel.tables['Transaksi']!;
    expect(tx.maxRows, 2);
    expect(tx.row(0).first?.value.toString(), 'Tanggal');
    final txRow = tx.row(1);
    expect(txRow[2]?.value.toString(), 'Pengeluaran');
    expect(txRow[3]?.value.toString(), 'Makan');
    expect((txRow[6]?.value as IntCellValue).value, -25000);
    expect(txRow[7]?.value.toString(), 'Kopi susu');

    final entry = excel.tables['Jurnal']!.row(1);
    expect(entry[2]?.value.toString(), 'Baik');
    expect(entry[5]?.value.toString(), 'pagi, kantor');

    final walletRow = excel.tables['Dompet']!.row(1);
    expect(walletRow[0]?.value.toString(), 'Tunai');
    expect((walletRow[3]?.value as IntCellValue).value, -25000);

    final budget = excel.tables['Budget']!.row(1);
    expect(budget[0]?.value.toString(), 'Makan');
    expect((budget[1]?.value as IntCellValue).value, 1000000);
    expect((budget[3]?.value as IntCellValue).value, 975000);
  });

  test('laporan Excel dapat memfilter rentang periode dan mengekstrak raw JSON', () async {
    final money = MoneyRepository(db);
    final journal = JournalRepository(db);
    final wallet = (await money.watchWallets().first).single;
    final food = (await money.watchCategories().first).firstWhere(
      (c) => c.systemKey == 'food',
    );

    // Transaksi di bulan Oktober 2026
    await money.saveTransaction(
      type: 'expense',
      amount: 15000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'Sarapan Oktober',
      occurredAt: DateTime(2026, 10, 5, 8, 0),
    );

    // Transaksi di bulan September 2026 (di luar bulan Oktober)
    await money.saveTransaction(
      type: 'expense',
      amount: 40000,
      walletId: wallet.id,
      categoryId: food.id,
      note: 'Makan September',
      occurredAt: DateTime(2026, 9, 20, 12, 0),
    );

    final snap = MoneySnapshot(
      wallets: await money.watchWallets().first,
      categories: await money.watchCategories().first,
      transactions: await money.watchTransactions().first,
      budgets: await money.watchBudgets().first,
    );

    const testRawJson = '{"format":"djournal-backup","version":1,"test":true}';

    // Build Excel dengan filter Bulan Oktober 2026 dan raw JSON
    final bytes = buildExcelReport(
      l: AppLocalizationsId(),
      money: snap,
      entries: await journal.watchEntries().first,
      now: DateTime(2026, 10, 8),
      period: BackupPeriod.thisMonth(DateTime(2026, 10, 1)),
      rawBackupJson: testRawJson,
    );

    final excel = Excel.decodeBytes(bytes);
    final tx = excel.tables['Transaksi']!;
    // Hanya 1 transaksi (Oktober) + 1 baris header = 2 baris
    expect(tx.maxRows, 2);
    expect(tx.row(1)[7]?.value.toString(), 'Sarapan Oktober');

    // Ekstrak kembali raw JSON
    final extracted = extractRawBackupJsonFromExcel(bytes);
    expect(extracted, testRawJson);
  });
}

