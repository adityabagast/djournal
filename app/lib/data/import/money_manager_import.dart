import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';

import '../../core/format.dart';
import '../db/app_database.dart';
import 'mm_backup_reader.dart';

/// Impor data dari aplikasi Money Manager (Realbyte), baik file cadangan
/// `.mmbak` (database SQLite) maupun ekspor `.xlsx`. Keduanya diubah ke
/// [MmRow] yang sama, lalu:
///
/// - akun → dompet (akun tunai utama → dompet tunai yang sudah ada; akun
///   yang sudah dihapus di Money Manager → dompet arsip),
/// - kategori → kategori bawaan kalau namanya cocok, selain itu kategori
///   baru dengan nama aslinya; sub kategori masuk ke catatan,
/// - "Edit saldo" → saldo awal dompet, supaya laporan tidak tercampur
///   angka koreksi,
/// - id transaksi diturunkan dari isi baris (waktu, akun, jenis, nominal),
///   jadi impor ulang, atau impor .mmbak lalu .xlsx yang lebih baru, tidak
///   membuat transaksi dobel.

enum MmKind { expense, income, transfer, adjustment }

enum MmSource { backup, excel }

/// Satu baris dari Money Manager, sudah dinormalkan.
class MmRow {
  const MmRow({
    required this.at,
    required this.kind,
    required this.account,
    required this.amount,
    String? keyAccount,
    this.toAccount,
    this.category,
    this.note,
  }) : keyAccount = keyAccount ?? account;

  /// Waktu lokal transaksi.
  final DateTime at;
  final MmKind kind;

  /// Nama akun, sekaligus identitas dompet.
  final String account;

  /// Nama akun asli untuk kunci impor. Beda dari [account] kalau akun yang
  /// dihapus diberi nama lain supaya tidak bentrok dengan akun aktif.
  final String keyAccount;

  /// Tujuan transfer.
  final String? toAccount;

  /// Kategori asli (tanpa sub kategori).
  final String? category;

  /// Catatan gabungan: sub kategori · catatan · deskripsi.
  final String? note;

  /// Rupiah. Untuk [MmKind.adjustment] bisa negatif.
  final int amount;
}

/// Isi file Money Manager yang sudah dibaca.
class MmData {
  const MmData({
    required this.source,
    required this.rows,
    this.accountTypes = const {},
    this.archivedAccounts = const {},
  });

  final MmSource source;
  final List<MmRow> rows;

  /// Nama akun → jenis dompet Nyawtat (cash/bank/ewallet/other), kalau
  /// file-nya menyimpan info itu (.mmbak).
  final Map<String, String> accountTypes;

  /// Akun yang sudah dihapus di Money Manager (.mmbak): jadi dompet arsip.
  final Set<String> archivedAccounts;
}

class MmFormatException implements Exception {
  MmFormatException(this.message);

  final String message;

  @override
  String toString() => 'MmFormatException: $message';
}

/// Baca file berdasarkan ekstensinya.
Future<MmData> readMoneyManagerFile(String name, Uint8List bytes) async {
  final lower = name.toLowerCase();
  if (lower.endsWith('.xlsx')) return parseMoneyManagerXlsx(bytes);
  if (lower.endsWith('.mmbak')) return readMoneyManagerBackup(bytes);
  throw MmFormatException('ekstensi tidak dikenal: $name');
}

/// Gabungkan potongan catatan yang tidak kosong.
String? _joinNote(Iterable<String?> parts) {
  final clean = [
    for (final p in parts)
      if (p != null && p.trim().isNotEmpty)
        p.trim().replaceAll(RegExp(r'\s*\n\s*'), ' '),
  ];
  return clean.isEmpty ? null : clean.join(' · ');
}

/// Bangun [MmRow] dari nilai mentah; dipakai pembaca .xlsx dan .mmbak.
MmRow? mmRow({
  required DateTime at,
  required String type,
  required String account,
  required num amount,
  String? keyAccount,
  String? category,
  String? subcategory,
  String? note,
  String? description,
}) {
  final value = amount.round().abs();
  if (account.trim().isEmpty || value == 0) return null;
  final isAdjustment = _isAdjustmentCategory(category);
  switch (type) {
    case 'income' || 'expense':
      if (isAdjustment) {
        return MmRow(
          at: at,
          kind: MmKind.adjustment,
          account: account,
          keyAccount: keyAccount,
          amount: type == 'income' ? value : -value,
        );
      }
      return MmRow(
        at: at,
        kind: type == 'income' ? MmKind.income : MmKind.expense,
        account: account,
        keyAccount: keyAccount,
        amount: value,
        category: category,
        note: _joinNote([subcategory, note, description]),
      );
    case 'transfer':
      // Di .xlsx tujuan transfer ada di kolom Kategori.
      if (category == null || category.trim().isEmpty) return null;
      return MmRow(
        at: at,
        kind: MmKind.transfer,
        account: account,
        keyAccount: keyAccount,
        toAccount: category,
        amount: value,
        note: _joinNote([note, description]),
      );
  }
  return null;
}

bool _isAdjustmentCategory(String? c) {
  final n = _norm(c ?? '');
  return n == 'edit saldo' || n == 'modified bal.' || n == 'modified bal';
}

// ---------------------------------------------------------------------------
// .xlsx
// ---------------------------------------------------------------------------

/// Kolom ekspor Money Manager (urutannya sama di semua bahasa):
/// Tanggal, Aset, Kategori, Sub kategori, Catatan, `<mata uang utama>`,
/// Pendapatan/Pengeluaran, Deskripsi, Total, Mata uang, ...
MmData parseMoneyManagerXlsx(Uint8List bytes) {
  final Excel book;
  try {
    book = Excel.decodeBytes(bytes);
  } catch (e) {
    throw MmFormatException('bukan file Excel: $e');
  }
  final sheet = book.tables.values.firstOrNull;
  if (sheet == null || sheet.maxRows < 1) {
    throw MmFormatException('sheet kosong');
  }

  const typeWords = {
    'pengeluaran': 'expense',
    'exp.': 'expense',
    'expense': 'expense',
    'pendapatan': 'income',
    'income': 'income',
    'transfer keluar': 'transfer',
    'transfer-out': 'transfer',
  };
  // "Transfer masuk" adalah pasangan dari "Transfer keluar": dilewati.
  const ignoredTypes = {'transfer masuk', 'transfer-in'};

  String? text(List<Data?> row, int i) {
    if (i >= row.length) return null;
    final v = row[i]?.value;
    return switch (v) {
      null => null,
      TextCellValue() => v.value.text,
      _ => v.toString(),
    };
  }

  num? number(List<Data?> row, int i) {
    if (i >= row.length) return null;
    return switch (row[i]?.value) {
      IntCellValue(:final value) => value,
      DoubleCellValue(:final value) => value,
      TextCellValue(:final value) => num.tryParse(
        (value.text ?? '').replaceAll(',', ''),
      ),
      _ => null,
    };
  }

  DateTime? date(List<Data?> row) {
    if (row.isEmpty) return null;
    return switch (row[0]?.value) {
      DateTimeCellValue(
        :final year,
        :final month,
        :final day,
        :final hour,
        :final minute,
        :final second,
        :final millisecond,
      ) =>
        DateTime(year, month, day, hour, minute, second, millisecond),
      DateCellValue(:final year, :final month, :final day) => DateTime(
        year,
        month,
        day,
      ),
      DoubleCellValue(:final value) => _fromSerial(value),
      IntCellValue(:final value) => _fromSerial(value),
      _ => null,
    };
  }

  final rows = <MmRow>[];
  var recognized = false;
  for (final row in sheet.rows.skip(1)) {
    final typeText = _norm(text(row, 6) ?? '');
    if (ignoredTypes.contains(typeText)) {
      recognized = true;
      continue;
    }
    final type = typeWords[typeText];
    final at = date(row);
    final amount = number(row, 5);
    if (type == null || at == null || amount == null) continue;
    recognized = true;
    final r = mmRow(
      at: at,
      type: type,
      account: text(row, 1) ?? '',
      amount: amount,
      category: text(row, 2),
      subcategory: text(row, 3),
      note: text(row, 4),
      description: text(row, 7),
    );
    if (r != null) rows.add(r);
  }
  if (!recognized) {
    throw MmFormatException('kolom tidak cocok dengan ekspor Money Manager');
  }
  return MmData(source: MmSource.excel, rows: rows);
}

/// Nomor seri tanggal Excel (hari sejak 30 Des 1899), jam lokal.
DateTime _fromSerial(num serial) {
  final ms = (serial * Duration.millisecondsPerDay).round();
  final utc = DateTime.utc(1899, 12, 30).add(Duration(milliseconds: ms));
  return DateTime(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
    utc.millisecond,
  );
}

// ---------------------------------------------------------------------------
// Rencana & penerapan
// ---------------------------------------------------------------------------

String _norm(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Nama tanpa emoji/simbol, untuk mencocokkan kategori bawaan.
String _plain(String s) =>
    _norm(s.replaceAll(RegExp(r'[^\p{L}\p{N}\s/]', unicode: true), ''));

/// Nama akun sebagai identitas dompet: spasi dirapikan, huruf besar/kecil
/// dipertahankan ("Krom Bank" lama ≠ "Krom bank" baru).
String _ident(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

const _uuid = Uuid();
const _ns = '6f1c2b52-9a54-4c55-9a8c-4d7a1f0e8e11';
String _stableId(String key) => _uuid.v5(_ns, key);

/// Kategori Money Manager yang punya padanan kategori bawaan Nyawtat.
const _systemMatch = {
  'expense': {
    'makan': 'food',
    'makanan': 'food',
    'food': 'food',
    'transport': 'transport',
    'transportasi': 'transport',
    'transportation': 'transport',
    'belanja': 'shopping',
    'shopping': 'shopping',
    'tagihan': 'bills',
    'bills': 'bills',
    'hiburan': 'entertainment',
    'entertainment': 'entertainment',
    'lainnya': 'other',
    'other': 'other',
    'others': 'other',
  },
  'income': {
    'gaji': 'salary',
    'salary': 'salary',
    'bonus': 'bonus',
    'lainnya': 'other_income',
    'other': 'other_income',
    'others': 'other_income',
  },
};

const _ewallets = {
  'dana',
  'gopay',
  'ovo',
  'shopeepay',
  'linkaja',
  'flip',
  'jenius pay',
};
const _cashNames = {'rupiah', 'tunai', 'cash', 'uang tunai', 'dompet'};

const _newCategoryColors = [
  '#9A3412',
  '#1E4E79',
  '#6B2C7A',
  '#7A5A00',
  '#1F5F4E',
  '#8A2D5C',
  '#2F5D8A',
  '#5B4A12',
  '#17624A',
  '#A3401C',
];

/// Ke mana satu akun Money Manager masuk.
class MmWalletPlan {
  MmWalletPlan({
    required this.sourceName,
    required this.name,
    required this.type,
    required this.id,
    required this.existing,
    required this.archive,
    required this.rowCount,
    this.rename = false,
  });

  final String sourceName;

  /// Nama dompet Nyawtat (yang sudah ada atau yang akan dibuat).
  final String name;
  final String type;
  final String id;

  /// true = dipetakan ke dompet yang sudah ada.
  final bool existing;

  /// Akun sudah dihapus di Money Manager: dompetnya diarsipkan.
  final bool archive;

  /// Dompet yang sudah ada diganti namanya menjadi [name].
  final bool rename;
  final int rowCount;
}

class MmCategoryPlan {
  MmCategoryPlan({
    required this.id,
    required this.kind,
    required this.name,
    required this.isNew,
  });

  final String id;
  final String kind;
  final String name;
  final bool isNew;
}

class _PlannedTx {
  _PlannedTx(this.id, this.row, this.walletId, this.toWalletId, this.category);

  final String id;
  final MmRow row;
  final String walletId;
  final String? toWalletId;
  final MmCategoryPlan? category;
}

/// Hasil pemeriksaan sebelum impor; ditampilkan sebagai pratinjau.
class MmImportPlan {
  MmImportPlan._({
    required this.source,
    required this.wallets,
    required this.categories,
    required this._newTx,
    required this._moves,
    required this._openingDelta,
    required this._applied,
    required this.alreadyImported,
    required this.skipped,
    required this.adjustmentRows,
    required this.first,
    required this.last,
  });

  final MmSource source;
  final List<MmWalletPlan> wallets;

  /// Hanya kategori yang dipakai transaksi baru.
  final List<MmCategoryPlan> categories;
  final List<_PlannedTx> _newTx;

  /// Transaksi yang sudah diimpor tapi dompetnya berubah (perbaikan impor
  /// lama): id → (dompet, dompet tujuan).
  final Map<String, (String, String?)> _moves;

  /// Perubahan saldo awal per dompet dari baris "Edit saldo".
  final Map<String, int> _openingDelta;

  /// Catatan "Edit saldo" yang sudah diterapkan: kunci baris → id dompet.
  final Map<String, String> _applied;

  /// Transaksi yang sudah ada dari impor sebelumnya.
  final int alreadyImported;

  /// Baris yang tidak bisa dipakai (mis. transfer ke dompet yang sama).
  final int skipped;

  /// Baris "Edit saldo" baru yang masuk ke saldo awal.
  final int adjustmentRows;
  final DateTime? first;
  final DateTime? last;

  int get newTransactions => _newTx.length;
  int get movedTransactions => _moves.length;
  int countOf(MmKind kind) => _newTx.where((t) => t.row.kind == kind).length;
  Iterable<MmCategoryPlan> get newCategories =>
      categories.where((c) => c.isNew);
  Iterable<MmWalletPlan> get newWallets => wallets.where((w) => !w.existing);
  bool get isEmpty =>
      _newTx.isEmpty &&
      _moves.isEmpty &&
      _openingDelta.values.every((d) => d == 0) &&
      !_archiveChanges;

  bool _archiveChanges = false;
}

class MmImportResult {
  const MmImportResult(this.transactions, this.wallets, this.categories);

  final int transactions;
  final int wallets;
  final int categories;
}

class MoneyManagerImporter {
  MoneyManagerImporter(this._db);

  final AppDatabase _db;

  /// Kunci app_settings (lokal) berisi baris "Edit saldo" yang sudah
  /// ditambahkan ke saldo awal (kunci baris → id dompet), supaya impor ulang
  /// tidak menjumlah dua kali dan bisa memindahkannya kalau pemetaan dompet
  /// berubah. Versi lama menyimpan daftar kunci saja.
  static const appliedAdjustmentsKey = 'import_mm_adjustments';

  Future<MmImportPlan> plan(MmData data) async {
    final wallets = await (_db.select(
      _db.wallets,
    )..where((w) => w.deletedAt.isNull())).get();
    final categories = await (_db.select(
      _db.categories,
    )..where((c) => c.deletedAt.isNull())).get();

    // --- Dompet ---------------------------------------------------------
    final usage = <String, int>{};
    for (final r in data.rows) {
      usage[_ident(r.account)] = (usage[_ident(r.account)] ?? 0) + 1;
      if (r.toAccount != null) {
        usage[_ident(r.toAccount!)] = (usage[_ident(r.toAccount!)] ?? 0) + 1;
      }
    }
    final archived = data.archivedAccounts.map(_ident).toSet();
    String typeOf(String ident) {
      final key = _norm(ident);
      final hinted = data.accountTypes.entries
          .where((e) => _ident(e.key) == ident)
          .map((e) => e.value)
          .firstOrNull;
      if (_ewallets.contains(key)) return 'ewallet';
      if (hinted != null) return hinted;
      if (_cashNames.contains(key)) return 'cash';
      return 'bank';
    }

    // Id dompet baru diturunkan dari nama. Kalau dua akun hanya beda huruf
    // besar, yang dihapus (atau yang lebih jarang dipakai) diberi akhiran.
    final idents = usage.keys.toList()
      ..sort((a, b) {
        final byArchive = (archived.contains(a) ? 1 : 0).compareTo(
          archived.contains(b) ? 1 : 0,
        );
        return byArchive != 0 ? byArchive : usage[b]!.compareTo(usage[a]!);
      });
    final plannedId = <String, String>{};
    final takenNorm = <String>{};
    for (final ident in idents) {
      final norm = _norm(ident);
      plannedId[ident] = takenNorm.add(norm)
          ? _stableId('mm-wallet|$norm')
          : _stableId(
              'mm-wallet|$norm|${archived.contains(ident) ? 'arsip' : ident}',
            );
    }

    // Pemetaan ke dompet yang sudah ada, berurutan dari yang paling pasti:
    // (nama persis, untuk akun yang hanya beda huruf besar) → id hasil impor
    // sebelumnya → nama persis → nama tanpa beda huruf besar (kalau tidak
    // ambigu) → dompet tunai untuk akun tunai utama.
    bool collides(String ident) =>
        idents.where((i) => _norm(i) == _norm(ident)).length > 1;
    final claimed = <String>{};
    final target = <String, Wallet>{};
    void byExactName(Iterable<String> which) {
      for (final ident in which.where((i) => !target.containsKey(i))) {
        final w = wallets
            .where((x) => !claimed.contains(x.id) && _ident(x.name) == ident)
            .firstOrNull;
        if (w != null && claimed.add(w.id)) target[ident] = w;
      }
    }

    byExactName(idents.where(collides));
    for (final ident in idents.where((i) => !target.containsKey(i))) {
      final w = wallets.where((x) => x.id == plannedId[ident]).firstOrNull;
      if (w != null && !claimed.contains(w.id) && claimed.add(w.id)) {
        target[ident] = w;
      }
    }
    for (final ident in idents.where((i) => !target.containsKey(i))) {
      final w = wallets
          .where((x) => !claimed.contains(x.id) && _ident(x.name) == ident)
          .firstOrNull;
      if (w != null && claimed.add(w.id)) target[ident] = w;
    }
    for (final ident in idents.where((i) => !target.containsKey(i))) {
      final sameNorm = idents.where((i) => _norm(i) == _norm(ident));
      if (sameNorm.length > 1) continue;
      final w = wallets
          .where(
            (x) => !claimed.contains(x.id) && _norm(x.name) == _norm(ident),
          )
          .firstOrNull;
      if (w != null && claimed.add(w.id)) target[ident] = w;
    }
    final cashIdent = idents
        .where((i) => !archived.contains(i) && typeOf(i) == 'cash')
        .firstOrNull;
    if (cashIdent != null && !target.containsKey(cashIdent)) {
      final cash = wallets
          .where(
            (x) => x.type == 'cash' && !x.isArchived && !claimed.contains(x.id),
          )
          .firstOrNull;
      if (cash != null && claimed.add(cash.id)) target[cashIdent] = cash;
    }

    // Dompet baru tidak boleh memakai id dompet yang sudah dipakai akun lain.
    for (final ident in idents.where((i) => !target.containsKey(i))) {
      if (claimed.contains(plannedId[ident]) ||
          wallets.any((w) => w.id == plannedId[ident])) {
        plannedId[ident] = _stableId('mm-wallet|${_norm(ident)}|$ident');
      }
    }

    var archiveChanges = false;
    final walletPlans = <String, MmWalletPlan>{};
    for (final ident in idents) {
      final existing = target[ident];
      final archive = archived.contains(ident);
      if (existing != null && archive && !existing.isArchived) {
        archiveChanges = true;
      }
      // Dompet hasil impor lama yang menggabungkan dua akun beda huruf besar
      // dikembalikan ke nama akunnya.
      final rename =
          existing != null && collides(ident) && _ident(existing.name) != ident;
      if (rename) archiveChanges = true;
      walletPlans[ident] = MmWalletPlan(
        sourceName: ident,
        name: existing == null || rename ? ident : existing.name,
        rename: rename,
        type: existing?.type ?? typeOf(ident),
        id: existing?.id ?? plannedId[ident]!,
        existing: existing != null,
        archive: archive,
        rowCount: usage[ident]!,
      );
    }

    // --- Kategori -------------------------------------------------------
    final categoryPlans = <String, MmCategoryPlan>{};
    MmCategoryPlan categoryFor(String kind, String? source) {
      final name = (source == null || source.trim().isEmpty)
          ? 'Lainnya'
          : source.trim();
      final key = '$kind|${_norm(name)}';
      return categoryPlans.putIfAbsent(key, () {
        final systemKey = _systemMatch[kind]![_plain(name)];
        final match = systemKey != null
            ? categories
                  .where((c) => c.kind == kind && c.systemKey == systemKey)
                  .firstOrNull
            : categories
                  .where((c) => c.kind == kind && _norm(c.name) == _norm(name))
                  .firstOrNull;
        if (match != null) {
          return MmCategoryPlan(
            id: match.id,
            kind: kind,
            name: match.name,
            isNew: false,
          );
        }
        return MmCategoryPlan(
          id: _stableId('mm-category|$key'),
          kind: kind,
          name: name,
          isNew: true,
        );
      });
    }

    // --- Transaksi & Edit saldo ------------------------------------------
    final appliedRaw = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(appliedAdjustmentsKey))).getSingleOrNull();
    final applied = <String, String?>{};
    if (appliedRaw != null) {
      final decoded = jsonDecode(appliedRaw.value);
      if (decoded is List) {
        // Versi lama: hanya kunci; dompetnya = dompet aktif dengan nama sama.
        for (final k in decoded.cast<String>()) {
          applied[k] = null;
        }
      } else {
        (decoded as Map).forEach((k, v) => applied['$k'] = v as String?);
      }
    }
    // Impor versi lama menaruh "Edit saldo" di dompet dengan id dari nama
    // akun (huruf kecil), atau di dompet tunai untuk akun tunai.
    String legacyTarget(String keyAccount) {
      final legacyId = _stableId('mm-wallet|${_norm(keyAccount)}');
      if (wallets.any((w) => w.id == legacyId)) return legacyId;
      final candidates =
          idents.where((i) => _norm(i) == _norm(keyAccount)).toList()..sort(
            (a, b) => (archived.contains(a) ? 1 : 0).compareTo(
              archived.contains(b) ? 1 : 0,
            ),
          );
      return walletPlans[candidates.first]!.id;
    }

    final seen = <String, int>{};
    final candidates = <_PlannedTx>[];
    final openingDelta = <String, int>{};
    final nextApplied = <String, String>{};
    var skipped = 0;
    var adjustmentRows = 0;
    DateTime? first;
    DateTime? last;

    for (final r in data.rows) {
      final from = walletPlans[_ident(r.account)]!;
      // Kunci stabil: sama untuk .mmbak dan .xlsx dari data yang sama.
      final base = [
        r.at.millisecondsSinceEpoch ~/ 1000,
        _norm(r.keyAccount),
        r.kind.name,
        r.amount,
      ].join('|');
      final n = seen[base] = (seen[base] ?? -1) + 1;
      final key = 'mm|$base|$n';

      if (r.kind == MmKind.adjustment) {
        if (applied.containsKey(key)) {
          final old = applied[key] ?? legacyTarget(r.keyAccount);
          if (old != from.id) {
            openingDelta[old] = (openingDelta[old] ?? 0) - r.amount;
            openingDelta[from.id] = (openingDelta[from.id] ?? 0) + r.amount;
          }
        } else {
          openingDelta[from.id] = (openingDelta[from.id] ?? 0) + r.amount;
          adjustmentRows++;
        }
        nextApplied[key] = from.id;
        continue;
      }
      String? to;
      if (r.kind == MmKind.transfer) {
        to = walletPlans[_ident(r.toAccount!)]!.id;
        if (to == from.id) {
          skipped++;
          continue;
        }
      }
      final cat = switch (r.kind) {
        MmKind.expense => categoryFor('expense', r.category),
        MmKind.income => categoryFor('income', r.category),
        _ => null,
      };
      candidates.add(_PlannedTx(_stableId(key), r, from.id, to, cat));
      if (first == null || r.at.isBefore(first)) first = r.at;
      if (last == null || r.at.isAfter(last)) last = r.at;
    }

    // Transaksi yang sudah pernah diimpor (termasuk yang sudah dihapus
    // user: jangan dihidupkan lagi). Yang dompetnya berubah dipindahkan.
    final existing = <String, MoneyTx>{};
    final ids = candidates.map((c) => c.id).toList();
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, (i + 500).clamp(0, ids.length));
      final rows = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.isIn(chunk))).get();
      for (final t in rows) {
        existing[t.id] = t;
      }
    }
    // Hanya .mmbak yang tahu akun mana yang dihapus, jadi hanya .mmbak yang
    // boleh memindahkan transaksi yang sudah diimpor.
    final moves = <String, (String, String?)>{};
    for (final c in data.source == MmSource.backup ? candidates : const []) {
      final t = existing[c.id];
      if (t == null || t.deletedAt != null) continue;
      if (t.walletId != c.walletId || t.toWalletId != c.toWalletId) {
        moves[c.id] = (c.walletId, c.toWalletId);
      }
    }
    final newTx = candidates.where((c) => !existing.containsKey(c.id)).toList();
    final usedCategories = {
      for (final t in newTx)
        if (t.category != null) t.category!.id: t.category!,
    };

    return MmImportPlan._(
      source: data.source,
      wallets: walletPlans.values.toList()
        ..sort((a, b) => b.rowCount.compareTo(a.rowCount)),
      categories: usedCategories.values.toList(),
      newTx: newTx,
      moves: moves,
      openingDelta: openingDelta,
      applied: {
        for (final e in applied.entries)
          e.key: e.value ?? legacyTarget(e.key.split('|')[2]),
        ...nextApplied,
      },
      alreadyImported: existing.length,
      skipped: skipped,
      adjustmentRows: adjustmentRows,
      first: first,
      last: last,
    ).._archiveChanges = archiveChanges;
  }

  Future<MmImportResult> apply(MmImportPlan plan) async {
    final now = DateTime.now().toUtc();
    var walletsCreated = 0;
    var categoriesCreated = 0;

    await _db.transaction(() async {
      // Dompet: buat yang baru, arsipkan akun yang dihapus di Money Manager.
      final maxOrder = _db.wallets.sortOrder.max();
      var order =
          ((await (_db.selectOnly(
                _db.wallets,
              )..addColumns([maxOrder])).getSingle()).read(maxOrder) ??
              -1) +
          1;
      for (final w in plan.wallets) {
        final row = await (_db.select(
          _db.wallets,
        )..where((x) => x.id.equals(w.id))).getSingleOrNull();
        final delta = plan._openingDelta[w.id] ?? 0;
        if (row == null) {
          await _db
              .into(_db.wallets)
              .insert(
                WalletsCompanion.insert(
                  id: w.id,
                  createdAt: now,
                  updatedAt: now,
                  name: w.name,
                  type: w.type,
                  openingBalance: Value(delta),
                  isArchived: Value(w.archive),
                  sortOrder: Value(order++),
                ),
              );
          walletsCreated++;
          continue;
        }
        final archive = w.archive && !row.isArchived;
        if (delta != 0 || row.deletedAt != null || archive || w.rename) {
          // Dompet yang pernah dihapus user dihidupkan lagi kalau dipakai.
          await (_db.update(
            _db.wallets,
          )..where((x) => x.id.equals(w.id))).write(
            WalletsCompanion(
              openingBalance: Value(row.openingBalance + delta),
              isArchived: archive ? const Value(true) : const Value.absent(),
              name: w.rename ? Value(w.name) : const Value.absent(),
              deletedAt: const Value(null),
              updatedAt: Value(now),
              isDirty: const Value(true),
            ),
          );
        }
      }
      // Saldo awal yang dipindah dari dompet di luar rencana (impor lama).
      for (final e in plan._openingDelta.entries) {
        if (plan.wallets.any((w) => w.id == e.key) || e.value == 0) continue;
        final row = await (_db.select(
          _db.wallets,
        )..where((x) => x.id.equals(e.key))).getSingleOrNull();
        if (row == null) continue;
        await (_db.update(_db.wallets)..where((x) => x.id.equals(e.key))).write(
          WalletsCompanion(
            openingBalance: Value(row.openingBalance + e.value),
            updatedAt: Value(now),
            isDirty: const Value(true),
          ),
        );
      }

      final catOrder = <String, int>{};
      for (final c in plan.newCategories) {
        final exists = await (_db.select(
          _db.categories,
        )..where((x) => x.id.equals(c.id))).getSingleOrNull();
        if (exists != null) {
          if (exists.deletedAt != null) {
            await (_db.update(
              _db.categories,
            )..where((x) => x.id.equals(c.id))).write(
              CategoriesCompanion(
                deletedAt: const Value(null),
                updatedAt: Value(now),
                isDirty: const Value(true),
              ),
            );
          }
          continue;
        }
        final index = catOrder[c.kind] = (catOrder[c.kind] ?? 0) + 1;
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: c.id,
                createdAt: now,
                updatedAt: now,
                name: c.name,
                kind: c.kind,
                color:
                    _newCategoryColors[categoriesCreated %
                        _newCategoryColors.length],
                sortOrder: Value(100 + index),
              ),
            );
        categoriesCreated++;
      }

      for (final e in plan._moves.entries) {
        await (_db.update(
          _db.transactions,
        )..where((t) => t.id.equals(e.key))).write(
          TransactionsCompanion(
            walletId: Value(e.value.$1),
            toWalletId: Value(e.value.$2),
            updatedAt: Value(now),
            isDirty: const Value(true),
          ),
        );
      }

      await _db.batch((b) {
        for (final t in plan._newTx) {
          b.insert(
            _db.transactions,
            TransactionsCompanion.insert(
              id: t.id,
              createdAt: now,
              updatedAt: now,
              type: switch (t.row.kind) {
                MmKind.income => 'income',
                MmKind.transfer => 'transfer',
                _ => 'expense',
              },
              amount: t.row.amount,
              walletId: t.walletId,
              toWalletId: Value(t.toWalletId),
              categoryId: Value(t.category?.id),
              note: Value(t.row.note),
              occurredAt: t.row.at.toUtc(),
              localDate: toLocalDate(t.row.at),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });

      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSetting(
              key: appliedAdjustmentsKey,
              value: jsonEncode(plan._applied),
            ),
          );
    });

    return MmImportResult(
      plan.newTransactions,
      walletsCreated,
      categoriesCreated,
    );
  }
}
