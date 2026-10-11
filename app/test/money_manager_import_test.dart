import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/import/money_manager_import.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Satu transaksi contoh, ditulis ke .xlsx dan .mmbak dengan isi yang sama.
typedef _Tx = ({
  DateTime at,
  String type, // Pengeluaran | Pendapatan | Transfer keluar
  String account,
  String category, // tujuan untuk transfer
  String sub,
  String note,
  int amount,
});

final _rows = <_Tx>[
  (
    at: DateTime(2026, 3, 1, 8, 0, 0, 120),
    type: 'Pendapatan',
    account: 'Mandiri',
    category: 'Edit saldo',
    sub: '',
    note: 'Selisih saldo',
    amount: 1000000,
  ),
  (
    at: DateTime(2026, 10, 1, 12, 30, 15, 500),
    type: 'Pengeluaran',
    account: 'Rupiah',
    category: '🍜 Makanan',
    sub: 'Jajanan',
    note: 'Bakso',
    amount: 15000,
  ),
  (
    at: DateTime(2026, 10, 1, 19, 0),
    type: 'Pengeluaran',
    account: 'Krom bank ',
    category: 'Admin',
    sub: '',
    note: '',
    amount: 2500,
  ),
  (
    at: DateTime(2026, 10, 2, 9, 0, 1, 999),
    type: 'Pendapatan',
    account: 'Krom Bank',
    category: '🏅 Bonus',
    sub: '',
    note: '',
    amount: 50000,
  ),
  (
    at: DateTime(2026, 10, 3, 10, 0),
    type: 'Transfer keluar',
    account: 'Mandiri',
    category: 'Rupiah',
    sub: '',
    note: 'Tarik tunai',
    amount: 300000,
  ),
];

Uint8List _xlsx(List<_Tx> rows) {
  final book = Excel.createExcel();
  final sheet = book['Sheet1'];
  sheet.appendRow([
    for (final h in [
      'Tanggal',
      'Aset',
      'Kategori',
      'Sub kategori',
      'Catatan',
      'IDR',
      'Pendapatan/Pengeluaran',
      'Deskripsi',
      'Total',
      'Mata uang',
    ])
      TextCellValue(h),
  ]);
  for (final r in rows) {
    sheet.appendRow([
      DateTimeCellValue.fromDateTime(r.at),
      TextCellValue(r.account),
      TextCellValue(r.category),
      TextCellValue(r.sub),
      TextCellValue(r.note),
      DoubleCellValue(r.amount.toDouble()),
      TextCellValue(r.type),
      TextCellValue(''),
      DoubleCellValue(r.amount.toDouble()),
      TextCellValue('IDR'),
    ]);
    // Pasangan transfer di ekspor: harus dilewati.
    if (r.type == 'Transfer keluar') {
      sheet.appendRow([
        DateTimeCellValue.fromDateTime(r.at),
        TextCellValue(r.category),
        TextCellValue(r.account),
        TextCellValue(''),
        TextCellValue(r.note),
        DoubleCellValue(r.amount.toDouble()),
        TextCellValue('Transfer masuk'),
      ]);
    }
  }
  return Uint8List.fromList(book.encode()!);
}

/// [deleted]: akun yang ditandai sudah dihapus di Money Manager.
Uint8List _mmbak(List<_Tx> rows, {Set<String> deleted = const {}}) {
  final dir = Directory.systemTemp.createTempSync('mmbak_test');
  final path = '${dir.path}/test.mmbak';
  final db = sqlite3.open(path);
  db.execute('''
    CREATE TABLE ASSETGROUP (uid TEXT, TYPE INTEGER);
    CREATE TABLE ASSETS (uid TEXT, NIC_NAME TEXT, groupUid TEXT,
      currencyUid TEXT, ZDATA TEXT);
    CREATE TABLE ZCATEGORY (uid TEXT, NAME TEXT, pUid TEXT);
    CREATE TABLE INOUTCOME (uid TEXT, assetUid TEXT, toAssetUid TEXT,
      ctgUid TEXT, DO_TYPE TEXT, ZMONEY TEXT, ZDATE TEXT, ZCONTENT TEXT,
      ZDATA TEXT, IS_DEL INTEGER);
    INSERT INTO ASSETGROUP VALUES ('1', 1), ('11', 11);
    INSERT INTO ZCATEGORY VALUES
      ('6', '🍜 Makanan', NULL), ('18', 'Jajanan', '6'),
      ('20', 'Admin', NULL), ('4', '🏅 Bonus', NULL);
  ''');
  final assets = db.prepare('INSERT INTO ASSETS VALUES (?, ?, ?, ?, ?)');
  for (final (uid, name, group) in [
    ('a1', 'Rupiah', '11'),
    ('a2', 'Mandiri', '1'),
    ('a3', 'Krom Bank', '1'),
    ('a4', 'Krom bank ', '1'),
  ]) {
    assets.execute([
      uid,
      name,
      group,
      'IDR_IDR',
      deleted.contains(name) ? '1' : '0',
    ]);
  }
  assets.close();
  const accounts = {
    'Rupiah': 'a1',
    'Mandiri': 'a2',
    'Krom Bank': 'a3',
    'Krom bank ': 'a4',
  };
  const categories = {'🏅 Bonus': '4', 'Admin': '20', 'Edit saldo': '-4'};
  final insert = db.prepare(
    'INSERT INTO INOUTCOME VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)',
  );
  var n = 0;
  for (final r in rows) {
    final transfer = r.type == 'Transfer keluar';
    final ctg = transfer
        ? ''
        : r.sub == 'Jajanan'
        ? '18'
        : categories[r.category]!;
    final doType = switch (r.type) {
      'Pendapatan' => '0',
      'Pengeluaran' => '1',
      _ => '3',
    };
    final ms = '${r.at.millisecondsSinceEpoch}';
    insert.execute([
      'tx${n++}',
      accounts[r.account],
      transfer ? accounts[r.category] : '',
      ctg,
      doType,
      '${r.amount}.0',
      ms,
      r.note,
      '',
    ]);
    if (transfer) {
      // Pasangan "transfer masuk" (DO_TYPE 4): harus dilewati.
      insert.execute([
        'tx${n++}',
        accounts[r.category],
        accounts[r.account],
        '',
        '4',
        '${r.amount}.0',
        ms,
        r.note,
        '',
      ]);
    }
  }
  insert.close();
  db.close();
  final bytes = File(path).readAsBytesSync();
  dir.deleteSync(recursive: true);
  return bytes;
}

void main() {
  late AppDatabase db;
  late MoneyManagerImporter importer;
  late MoneyRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    importer = MoneyManagerImporter(db);
    repo = MoneyRepository(db);
  });

  tearDown(() => db.close());

  Future<MoneySnapshot> snapshot() async => MoneySnapshot(
    wallets: await repo.watchWallets().first,
    categories: await repo.watchCategories().first,
    transactions: await repo.watchTransactions().first,
  );

  test('xlsx: dompet, kategori, catatan, transfer, dan saldo awal', () async {
    final data = parseMoneyManagerXlsx(_xlsx(_rows));
    final plan = await importer.plan(data);

    expect(plan.newTransactions, 4);
    expect(plan.countOf(MmKind.transfer), 1);
    expect(plan.adjustmentRows, 1);
    // Rupiah → Tunai yang sudah ada. Nama yang hanya beda huruf besar
    // tetap dua dompet (bisa jadi akun lama yang sudah dihapus).
    final byName = {for (final w in plan.wallets) w.sourceName: w};
    expect(byName['Rupiah']!.existing, isTrue);
    expect(byName['Rupiah']!.name, 'Tunai');
    expect(byName.keys, containsAll(['Krom Bank', 'Krom bank']));
    // Makanan & Bonus cocok dengan kategori bawaan; Admin kategori baru.
    expect(plan.newCategories.map((c) => c.name), ['Admin']);

    await importer.apply(plan);
    final snap = await snapshot();
    final mandiri = snap.wallets.firstWhere((w) => w.name == 'Mandiri');
    final cash = snap.wallets.firstWhere((w) => w.name == 'Tunai');
    final kromOld = snap.wallets.firstWhere((w) => w.name == 'Krom Bank');
    final kromNew = snap.wallets.firstWhere((w) => w.name == 'Krom bank');
    expect(mandiri.openingBalance, 1000000);
    expect(snap.balanceOf(mandiri.id), 1000000 - 300000);
    expect(snap.balanceOf(cash.id), -15000 + 300000);
    expect(snap.balanceOf(kromOld.id), 50000);
    expect(snap.balanceOf(kromNew.id), -2500);

    final bakso = snap.transactions.firstWhere((t) => t.amount == 15000);
    expect(bakso.note, 'Jajanan · Bakso');
    expect(snap.categoryById[bakso.categoryId]!.systemKey, 'food');
    final transfer = snap.transactions.firstWhere((t) => t.type == 'transfer');
    expect(transfer.categoryId, isNull);
    expect(transfer.toWalletId, cash.id);
    expect(transfer.occurredAt.toLocal(), DateTime(2026, 10, 3, 10, 0));
  });

  test('impor ulang tidak dobel, saldo awal tidak dijumlah dua kali', () async {
    final bytes = _xlsx(_rows);
    await importer.apply(await importer.plan(parseMoneyManagerXlsx(bytes)));
    final again = await importer.plan(parseMoneyManagerXlsx(bytes));

    expect(again.isEmpty, isTrue);
    expect(again.alreadyImported, 4);
    await importer.apply(again);
    final snap = await snapshot();
    expect(snap.transactions, hasLength(4));
    expect(
      snap.wallets.firstWhere((w) => w.name == 'Mandiri').openingBalance,
      1000000,
    );
  });

  test('.mmbak lalu .xlsx yang lebih baru hanya menambah data baru', () async {
    final older = _rows.take(4).toList();
    final backup = await readMoneyManagerFile('cadangan.mmbak', _mmbak(older));
    expect(backup.source, MmSource.backup);
    final first = await importer.plan(backup);
    expect(first.newTransactions, 3);
    expect(first.adjustmentRows, 1);
    await importer.apply(first);

    final export = await readMoneyManagerFile('ekspor.xlsx', _xlsx(_rows));
    final second = await importer.plan(export);
    expect(second.alreadyImported, 3);
    expect(second.newTransactions, 1);
    expect(second.countOf(MmKind.transfer), 1);
    expect(second.adjustmentRows, 0);
    expect(second.newCategories, isEmpty);
  });

  test('akun yang dihapus di Money Manager jadi dompet arsip', () async {
    final data = await readMoneyManagerFile(
      'c.mmbak',
      _mmbak(_rows, deleted: {'Krom Bank'}),
    );
    await importer.apply(await importer.plan(data));
    final snap = await snapshot();

    // "Krom Bank" lama terpisah dari "Krom bank" baru dan diarsipkan.
    expect(snap.wallets.map((w) => w.name), isNot(contains('Krom Bank')));
    final old = snap.archivedWallets.single;
    final active = snap.wallets.firstWhere((w) => w.name == 'Krom bank');
    expect(old.name, 'Krom Bank');
    expect(snap.balanceOf(old.id), 50000);
    expect(snap.balanceOf(active.id), -2500);
    // Saldo dompet arsip tidak ikut total, transaksinya tetap ada.
    expect(snap.totalBalance, 1000000 - 300000 + (-15000 + 300000) - 2500);
    expect(snap.transactions.where((t) => t.walletId == old.id), hasLength(1));
  });

  test('impor ulang .mmbak memperbaiki hasil impor versi lama', () async {
    // Versi lama: "Krom Bank" dan "Krom bank" digabung jadi satu dompet,
    // dan catatan Edit saldo berupa daftar kunci.
    final merged = parseMoneyManagerXlsx(
      _xlsx([
        for (final r in _rows)
          (
            at: r.at,
            type: r.type,
            account: r.account.trim().toLowerCase() == 'krom bank'
                ? 'Krom Bank'
                : r.account,
            category: r.category,
            sub: r.sub,
            note: r.note,
            amount: r.amount,
          ),
      ]),
    );
    final legacy = MmData(
      source: merged.source,
      rows: [
        for (final (i, r) in merged.rows.indexed)
          MmRow(
            at: r.at,
            kind: r.kind,
            account: r.account,
            keyAccount: _rows[i].account,
            amount: r.amount,
            toAccount: r.toAccount,
            category: r.category,
            note: r.note,
          ),
      ],
    );
    await importer.apply(await importer.plan(legacy));
    final applied =
        await (db.select(db.appSettings)..where(
              (s) => s.key.equals(MoneyManagerImporter.appliedAdjustmentsKey),
            ))
            .getSingle();
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSetting(
            key: applied.key,
            value: jsonEncode((jsonDecode(applied.value) as Map).keys.toList()),
          ),
        );
    expect(
      (await snapshot()).wallets.where((w) => w.name == 'Krom Bank'),
      hasLength(1),
    );

    final backup = await readMoneyManagerFile(
      'c.mmbak',
      _mmbak(_rows, deleted: {'Krom Bank'}),
    );
    final repair = await importer.plan(backup);
    expect(repair.newTransactions, 0);
    expect(repair.movedTransactions, 1);
    await importer.apply(repair);

    final snap = await snapshot();
    final active = snap.wallets.firstWhere((w) => w.name == 'Krom bank');
    final old = snap.archivedWallets.single;
    expect(old.name, 'Krom Bank');
    expect(snap.balanceOf(active.id), -2500);
    expect(snap.balanceOf(old.id), 50000);
    expect(
      snap.wallets.firstWhere((w) => w.name == 'Mandiri').openingBalance,
      1000000,
    );
    // Setelah diperbaiki, impor .xlsx atau .mmbak lagi tidak mengubah apa-apa.
    expect(
      (await importer.plan(parseMoneyManagerXlsx(_xlsx(_rows)))).isEmpty,
      isTrue,
    );
    expect((await importer.plan(backup)).isEmpty, isTrue);
  });

  test('file yang bukan dari Money Manager ditolak', () async {
    expect(
      () => readMoneyManagerFile('a.xlsx', Uint8List.fromList([1, 2, 3])),
      throwsA(isA<MmFormatException>()),
    );
    expect(
      () => readMoneyManagerFile('a.csv', Uint8List(0)),
      throwsA(isA<MmFormatException>()),
    );
  });
}
