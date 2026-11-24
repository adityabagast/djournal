import 'dart:convert';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/core/format.dart';
import 'package:djournal/features/backup/data/excel_report.dart';
import 'package:djournal/features/backup/domain/backup_period.dart';
import 'package:djournal/features/journal/data/journal_repository.dart';
import 'package:djournal/features/money/domain/money_snapshot.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/l10n/app_localizations_en.dart';
import 'package:djournal/l10n/app_localizations_id.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// Nilai tersimpan setiap rumus: sheet → sel → isi.
Map<String, Map<String, String>> cachedValues(List<int> bytes) {
  final files = {
    for (final f in ZipDecoder().decodeBytes(bytes).files)
      f.name: utf8.decode(f.content as List<int>),
  };
  final targets = {
    for (final r in XmlDocument.parse(files['xl/_rels/workbook.xml.rels']!)
        .findAllElements('Relationship'))
      r.getAttribute('Id')!: r.getAttribute('Target')!,
  };
  String path(XmlElement s) =>
      'xl/${targets[s.getAttribute('r:id')]!.replaceFirst('/xl/', '')}';
  return {
    for (final s in XmlDocument.parse(files['xl/workbook.xml']!)
        .findAllElements('sheet'))
      s.getAttribute('name')!: {
        for (final c
            in XmlDocument.parse(files[path(s)]!).findAllElements('c'))
          if (c.getElement('f') != null)
            c.getAttribute('r')!: c.getElement('v')!.innerText,
      },
  };
}

void main() {
  final at = DateTime(2026);
  var no = 0;

  Wallet wallet(String id, String name, [int opening = 0]) => Wallet(
    id: id,
    createdAt: at,
    updatedAt: at,
    isDirty: false,
    name: name,
    type: 'cash',
    openingBalance: opening,
    sortOrder: 0,
    isArchived: false,
  );

  Category category(String id, String name, {String? parent, String kind = 'expense'}) =>
      Category(
        id: id,
        createdAt: at,
        updatedAt: at,
        isDirty: false,
        name: name,
        kind: kind,
        color: '#1F5F4E',
        parentId: parent,
        sortOrder: 0,
        isArchived: false,
      );

  MoneyTx tx(
    String type,
    int amount,
    String date, {
    String w = 'a',
    String? to,
    String? cat,
    String? note,
  }) => MoneyTx(
    id: 't${no++}',
    createdAt: at,
    updatedAt: at,
    isDirty: false,
    type: type,
    amount: amount,
    walletId: w,
    toWalletId: to,
    categoryId: cat,
    note: note,
    occurredAt: parseLocalDate(date).add(const Duration(hours: 9)),
    localDate: date,
  );

  MoneySnapshot sample() => MoneySnapshot(
    wallets: [
      wallet('a', 'Tunai', 1000),
      wallet('b', 'tunai'),
      wallet('c', '=Bank*?', 500),
    ],
    categories: [
      category('makan', 'Makan'),
      category('kopi', 'Kopi', parent: 'makan'),
      category('jalan', 'Jalan~'),
      category('gaji', 'Gaji', kind: 'income'),
    ],
    transactions: [
      tx('transfer', 300, '2026-10-06', to: 'c'),
      tx('transfer', 200, '2026-10-05', w: 'c', to: 'b'),
      tx('income', 5000, '2026-10-04', w: 'b', cat: 'gaji'),
      tx('expense', 70, '2026-10-03', cat: 'jalan', note: '=1+1'),
      tx('expense', 40, '2026-10-02', cat: 'kopi', note: 'a\u0001b'),
      tx('expense', 30, '2026-10-02', cat: 'makan'),
      tx('expense', 900, '2026-09-01', cat: 'makan'),
    ],
  );

  List<int> build(
    MoneySnapshot money, {
    AppLocalizations? l,
    DateTime? now,
    BackupPeriod? period,
    String? raw,
    List<JournalEntry> entries = const [],
  }) => buildExcelReport(
    l: l ?? AppLocalizationsId(),
    money: money,
    entries: entries,
    now: now ?? DateTime(2026, 10, 8),
    period: period,
    rawBackupJson: raw,
  );

  test('saldo dan budget sama dengan MoneySnapshot', () {
    final snap = sample();
    final v = cachedValues(build(snap));
    expect(
      [for (var r = 2; r <= 4; r++) v['Dompet']!['E$r']],
      [for (final id in ['a', 'b', 'c']) '${snap.balanceOf(id)}'],
    );
    expect(
      v['Dompet']!['E5'],
      '${['a', 'b', 'c'].fold<int>(0, (s, id) => s + snap.balanceOf(id))}',
    );
    expect(v['Budget']!['C4'], '${snap.spentIn('makan', '2026-10')}');
    expect(v['Budget']!['C5'], '${snap.spentIn('jalan', '2026-10')}');
    expect(v['Budget']!['D4'], '-', reason: 'tanpa batas');
  });

  test('kategori senama beda huruf tidak terhitung dobel', () {
    final snap = MoneySnapshot(
      wallets: [wallet('a', 'Tunai')],
      categories: [
        category('x', 'Makan'),
        category('y', 'makan'),
        category('z', 'Makan', kind: 'income'),
      ],
      transactions: [
        tx('expense', 10, '2026-10-02', cat: 'x'),
        tx('expense', 25, '2026-10-02', cat: 'y'),
        tx('income', 99, '2026-10-02', cat: 'z'),
      ],
    );
    final bytes = build(snap);
    final v = cachedValues(bytes)['Budget']!;
    expect([v['C4'], v['C5']], ['10', '25']);
    final t = Excel.decodeBytes(bytes).tables;
    expect('${t['Budget']!.row(4)[0]?.value}', 'makan (2)');
    expect(
      [for (final r in t['Transaksi']!.rows.skip(3)) '${r[3]?.value}'],
      unorderedEquals(['Makan', 'makan (2)', 'Makan']),
      reason: 'pemasukan senama tidak ikut diberi nomor',
    );
  });

  test('ringkasan bulan berjalan dan kategori terbesar', () {
    final s = cachedValues(build(sample()))['Ringkasan']!;
    expect(
      [s['B7'], s['B8'], s['B9'], s['B10'], s['B11']],
      ['5000', '140', '4860', '18', '6'],
      reason: 'rata-rata 140 / 8 hari = 17,5',
    );
    // Dua kategori 70: yang barisnya lebih bawah di sheet bantu lebih dulu.
    expect({s['F7'], s['F8']}, {'Makan', 'Jalan~'});
    expect([s['G7'], s['G8'], s['F9'], s['G12']], ['70', '70', '-', '0']);
    // Per bulan: September lalu Oktober.
    expect([s['C16'], s['B17'], s['C17']], ['900', '5000', '140']);
  });

  test('total Transaksi mengabaikan transfer', () {
    final t = cachedValues(build(sample()))['Transaksi']!;
    expect([t['H1'], t['I1'], t['G1']], ['5000', '1040', '3960']);
  });

  test('nama kembar dibedakan, nama berisi karakter khusus dicocokkan persis',
      () {
    final t = Excel.decodeBytes(build(sample())).tables;
    expect('${t['Dompet']!.row(2)[0]?.value}', 'tunai (2)');
    expect('${t['Transaksi']!.row(7)[4]?.value}', 'tunai (2)');
    String formula(String sheet, int row, int c) =>
        (t[sheet]!.row(row)[c]!.value as FormulaCellValue).formula;
    expect(formula('Dompet', 1, 3), startsWith('SUMIFS'));
    expect(formula('Dompet', 3, 3), startsWith('SUMPRODUCT'));
    expect(formula('Budget', 4, 2), startsWith('SUMPRODUCT'), reason: 'Jalan~');
  });

  test('teks user tidak pernah jadi rumus; karakter kontrol dibuang', () {
    final rows = Excel.decodeBytes(build(sample())).tables['Transaksi']!.rows;
    final notes = [for (final r in rows.skip(3)) r[9]?.value];
    expect(notes.whereType<FormulaCellValue>(), isEmpty);
    expect(notes.map((n) => '$n'), containsAll(['=1+1', 'ab']));
  });

  test('periode: saldo akhir tetap benar walau transaksi lama tidak ada', () {
    final snap = sample();
    final v = cachedValues(
      build(snap, period: BackupPeriod.thisMonth(DateTime(2026, 10, 8))),
    );
    expect(v['Transaksi']!['I1'], '140');
    expect(v['Dompet']!['E2'], '${snap.balanceOf('a')}');
  });

  test('periode lampau: saldo per akhir periode, bukan saldo sekarang', () {
    final bytes = build(
      sample(),
      period: BackupPeriod.custom(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
    );
    final v = cachedValues(bytes);
    expect(v['Dompet']!['E2'], '${1000 - 900}');
    expect(v['Ringkasan']!['B8'], '900', reason: 'bulan awal = September');
  });

  test('tanpa data apa pun: file sah, tanpa pembagian nol', () {
    final bytes = build(
      MoneySnapshot(wallets: [], categories: [], transactions: []),
      now: DateTime(2026, 1, 1),
    );
    final s = cachedValues(bytes)['Ringkasan']!;
    expect([s['B10'], s['H7']], ['0', '0']);
    expect(Excel.decodeBytes(bytes).tables['Transaksi']!.row(2), isNotEmpty);
  });

  test('jurnal sangat panjang dipotong, mood terhitung', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = JournalRepository(db);
    await repo.saveEntry(
      entryDate: '2026-10-08',
      entryTime: '07:30',
      mood: 4,
      title: 'Panjang',
      body: '😺' * 20000,
      tags: const [],
    );
    final bytes = build(sample(), entries: await repo.watchEntries().first);
    final row = Excel.decodeBytes(bytes).tables['Jurnal']!.row(1);
    expect('${row[4]?.value}'.length, lessThanOrEqualTo(32767));
    final s = cachedValues(bytes)['Ringkasan']!;
    // Dua bulan (16-17), header mood di baris 20, Baik = mood ke-4.
    expect(s['B24'], '1');
  });

  test('bahasa Inggris: rumus memakai nama sheet dan jenis Inggris', () {
    final t = Excel.decodeBytes(build(sample(), l: AppLocalizationsEn())).tables;
    expect(t.keys, containsAll(['Summary', 'Transactions', 'Journal', 'Wallets']));
    String f(String sheet, int row, int c) =>
        (t[sheet]!.row(row)[c]!.value as FormulaCellValue).formula;
    expect(f('Summary', 6, 1), contains("'Transactions'!"));
    expect(f('Transactions', 3, 7), contains('Income'));
  });

  test('data pemulihan besar: tiap sel di bawah batas dan kembali utuh', () {
    final r = Random(3);
    final body = String.fromCharCodes(
      List.generate(150000, (_) => 97 + r.nextInt(26)),
    );
    final raw = '{"x":"$body"}';
    final bytes = build(sample(), raw: raw);
    for (final row in Excel.decodeBytes(bytes).tables['_Data_Sistem']!.rows) {
      expect('${row.first?.value}'.length, lessThanOrEqualTo(32767));
    }
    expect(extractRawBackupJsonFromExcel(bytes), raw);
  });

  test('file lama (JSON di satu sel) tetap bisa dipulihkan', () {
    const json = '{"format":"djournal-backup"}';
    final old = Excel.createExcel();
    old['_Data_Sistem'].appendRow([TextCellValue(json)]);
    expect(extractRawBackupJsonFromExcel(old.encode()!), json);
  });
}
