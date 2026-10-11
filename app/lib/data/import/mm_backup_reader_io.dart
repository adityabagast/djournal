import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'money_manager_import.dart';

/// Baca file cadangan Money Manager (.mmbak = database SQLite).
///
/// Tabel yang dipakai: ASSETS (akun) + ASSETGROUP (jenis akun), ZCATEGORY
/// (kategori, sub kategori lewat pUid), INOUTCOME (transaksi).
/// DO_TYPE: 0 pemasukan, 1 pengeluaran, 3 transfer keluar, 4 transfer masuk
/// (pasangan dari 3, dilewati), 7/8 koreksi saldo +/−. Kategori "-4" adalah
/// "Edit saldo". ASSETS.ZDATA = '1' menandai akun yang sudah dihapus user;
/// transaksinya tetap ada di Money Manager, jadi diimpor ke dompet arsip.
Future<MmData> readMoneyManagerBackup(Uint8List bytes) async {
  // sqlite3 hanya bisa membuka file, jadi salin dulu ke folder sementara.
  final dir = await Directory.systemTemp.createTemp('mmbak');
  final file = File('${dir.path}/backup.mmbak');
  await file.writeAsBytes(bytes, flush: true);
  final Database db;
  try {
    db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  } catch (e) {
    await dir.delete(recursive: true);
    throw MmFormatException('bukan database SQLite: $e');
  }
  try {
    return _read(db);
  } on SqliteException catch (e) {
    throw MmFormatException('bukan cadangan Money Manager: $e');
  } finally {
    db.close();
    await dir.delete(recursive: true);
  }
}

MmData _read(Database db) {
  final groupType = {
    for (final r in db.select('SELECT uid, TYPE FROM ASSETGROUP'))
      '${r['uid']}': switch (r['TYPE']) {
        11 => 'cash',
        1 || 3 || 4 => 'bank',
        6 => 'ewallet',
        _ => 'other',
      },
  };

  final assets = db.select(
    'SELECT uid, NIC_NAME, groupUid, currencyUid, ZDATA FROM ASSETS',
  );
  String clean(Object? name) =>
      '${name ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' ');
  final activeNames = {
    for (final r in assets)
      if ('${r['ZDATA']}' != '1') clean(r['NIC_NAME']),
  };
  // uid → (nama dompet, nama asli untuk kunci impor)
  final accountName = <String, (String, String)>{};
  final accountTypes = <String, String>{};
  final archivedAccounts = <String>{};
  for (final r in assets) {
    final original = '${r['NIC_NAME'] ?? ''}';
    final deleted = '${r['ZDATA']}' == '1';
    // Akun terhapus yang namanya persis sama dengan akun aktif dibedakan.
    final name = deleted && activeNames.contains(clean(original))
        ? '${clean(original)} (dihapus)'
        : clean(original);
    accountName['${r['uid']}'] = (name, original);
    if (deleted) archivedAccounts.add(name);
    // Akun mata uang asing tidak dianggap dompet tunai utama.
    final foreign = !'${r['currencyUid'] ?? ''}'.endsWith('_IDR');
    final type = groupType['${r['groupUid']}'] ?? 'other';
    accountTypes[name] = foreign && type == 'cash' ? 'other' : type;
  }

  final categories = <String, (String, String?)>{
    for (final r in db.select('SELECT uid, NAME, pUid FROM ZCATEGORY'))
      '${r['uid']}': ('${r['NAME'] ?? ''}', r['pUid'] as String?),
  };
  (String?, String?) categoryOf(String uid) {
    final c = categories[uid];
    if (c == null) return (null, null);
    final parent = c.$2 == null || c.$2!.isEmpty || c.$2 == '0'
        ? null
        : categories[c.$2!];
    return parent == null ? (c.$1, null) : (parent.$1, c.$1);
  }

  final rows = <MmRow>[];
  for (final r in db.select('''
    SELECT assetUid, toAssetUid, ctgUid, DO_TYPE, ZMONEY, ZDATE, ZCONTENT, ZDATA
    FROM INOUTCOME WHERE IFNULL(IS_DEL, 0) = 0 ORDER BY ZDATE
  ''')) {
    final (account, keyAccount) =
        accountName['${r['assetUid']}'] ?? (null, null);
    final ms = int.tryParse('${r['ZDATE']}');
    final amount = num.tryParse('${r['ZMONEY']}');
    if (account == null || ms == null || amount == null) continue;
    final at = DateTime.fromMillisecondsSinceEpoch(ms);
    final ctgUid = '${r['ctgUid'] ?? ''}';
    final (category, sub) = ctgUid == '-4'
        ? ('Edit saldo', null)
        : categoryOf(ctgUid);

    final row = switch ('${r['DO_TYPE']}') {
      '0' || '1' => mmRow(
        at: at,
        type: '${r['DO_TYPE']}' == '0' ? 'income' : 'expense',
        account: account,
        keyAccount: keyAccount,
        amount: amount,
        category: category,
        subcategory: sub,
        note: r['ZCONTENT'] as String?,
        description: r['ZDATA'] as String?,
      ),
      '3' => mmRow(
        at: at,
        type: 'transfer',
        account: account,
        keyAccount: keyAccount,
        amount: amount,
        category: accountName['${r['toAssetUid']}']?.$1,
        note: r['ZCONTENT'] as String?,
        description: r['ZDATA'] as String?,
      ),
      '7' || '8' => mmRow(
        at: at,
        type: '${r['DO_TYPE']}' == '7' ? 'income' : 'expense',
        account: account,
        keyAccount: keyAccount,
        amount: amount,
        category: 'Edit saldo',
      ),
      _ => null,
    };
    if (row != null) rows.add(row);
  }
  return MmData(
    source: MmSource.backup,
    rows: rows,
    accountTypes: accountTypes,
    archivedAccounts: archivedAccounts,
  );
}
