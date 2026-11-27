import '../../../core/database/app_database.dart';
import 'money_snapshot.dart';
import 'tx_text_parser.dart';

enum TxDraftState {
  /// Ditawarkan, belum dijawab.
  pending,

  /// Akan dicatat saat jurnal disimpan.
  accepted,
  dismissed,

  /// Sudah ada transaksi senilai itu di tanggal yang sama.
  recorded,
}

/// Calon transaksi dari jurnal, sebelum disimpan.
class TxDraft {
  const TxDraft({
    required this.key,
    required this.note,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    this.state = TxDraftState.pending,
    this.manual = false,
    this.receiptPath,
  });

  final String key;
  final String note;
  final int amount;

  /// expense | income
  final String type;
  final String? categoryId;
  final String walletId;
  final TxDraftState state;

  /// Ditambah lewat tombol, bukan dari teks.
  final bool manual;

  /// Foto nota: salah satu foto catatan, atau foto baru khusus transaksi.
  final String? receiptPath;

  TxDraft copyWith({
    String? note,
    int? amount,
    String? type,
    String? categoryId,
    String? walletId,
    TxDraftState? state,
  }) => TxDraft(
    key: key,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    walletId: walletId ?? this.walletId,
    state: state ?? this.state,
    manual: manual,
    receiptPath: receiptPath,
  );
}

/// Pilihan user atas transaksi yang dikenali di cerita, selama form terbuka.
class TxSuggestionController {
  final _accepted = <String>{};
  final _dismissed = <String>{};
  final _overrides = <String, TxDraft>{};
  final _manual = <TxDraft>[];
  var _manualCount = 0;

  /// Foto di catatan yang sedang ditulis; bisa dipilih jadi nota.
  List<String> photos = const [];

  /// Draft lain (diterima) yang sudah memakai foto [path] sebagai nota.
  TxDraft? receiptUser(String path, {required String exceptKey}) {
    for (final d in [
      for (final MapEntry(:key, :value) in _overrides.entries)
        if (_accepted.contains(key)) value,
      ..._manual,
    ]) {
      if (d.key != exceptKey && d.receiptPath == path) return d;
    }
    return null;
  }

  /// Ada jawaban atau tambahan yang belum disimpan.
  bool get hasChoices =>
      _accepted.isNotEmpty || _dismissed.isNotEmpty || _manual.isNotEmpty;

  /// Ada transaksi yang akan hilang kalau form ditutup tanpa disimpan.
  bool get hasAccepted => _accepted.isNotEmpty || _manual.isNotEmpty;

  String newManualKey() => 'manual-${_manualCount++}';

  /// Semua calon transaksi: dari [text] (urut kemunculan), lalu tambahan
  /// manual. Kosong kalau belum ada dompet.
  List<TxDraft> items(String text, String date, MoneySnapshot snap) {
    if (snap.wallets.isEmpty) return const [];
    // Tiap transaksi yang sudah ada hanya menutup satu usulan senilai sama.
    final recorded = <(String, int), int>{};
    for (final t in snap.onDate(date)) {
      recorded.update((t.type, t.amount), (n) => n + 1, ifAbsent: () => 1);
    }
    return [
      for (final p in parseTxText(text))
        if (_overrides[p.key] ?? _guess(p, snap) case final d)
          d.copyWith(state: _stateOf(d, recorded)),
      ..._manual,
    ];
  }

  TxDraftState _stateOf(TxDraft d, Map<(String, int), int> recorded) {
    final slot = (d.type, d.amount);
    final left = recorded[slot] ?? 0;
    if (left > 0) {
      recorded[slot] = left - 1;
      return TxDraftState.recorded;
    }
    if (_accepted.contains(d.key)) return TxDraftState.accepted;
    if (_dismissed.contains(d.key)) return TxDraftState.dismissed;
    return TxDraftState.pending;
  }

  List<TxDraft> pending(String text, String date, MoneySnapshot snap) =>
      _where(text, date, snap, TxDraftState.pending);

  /// Yang disimpan sebagai transaksi saat jurnal disimpan.
  List<TxDraft> accepted(String text, String date, MoneySnapshot snap) =>
      _where(text, date, snap, TxDraftState.accepted);

  List<TxDraft> _where(
    String text,
    String date,
    MoneySnapshot snap,
    TxDraftState state,
  ) => items(text, date, snap).where((d) => d.state == state).toList();

  void accept(String key) {
    _dismissed.remove(key);
    _accepted.add(key);
  }

  void dismiss(String key) {
    _accepted.remove(key);
    _dismissed.add(key);
  }

  /// Simpan hasil ubah atau tambah manual; otomatis diterima.
  void save(TxDraft d) {
    if (!d.manual) {
      _overrides[d.key] = d;
      accept(d.key);
      return;
    }
    final done = d.copyWith(state: TxDraftState.accepted);
    final i = _manual.indexWhere((m) => m.key == d.key);
    i < 0 ? _manual.add(done) : _manual[i] = done;
  }

  /// Batal dicatat: usulan dari teks kembali ditawarkan, tambahan manual
  /// dihapus.
  void undo(TxDraft d) {
    if (d.manual) {
      _manual.removeWhere((m) => m.key == d.key);
    } else {
      _accepted.remove(d.key);
      _dismissed.remove(d.key);
    }
  }

  static TxDraft _guess(ParsedTx p, MoneySnapshot snap) => TxDraft(
    key: p.key,
    note: p.note,
    amount: p.amount,
    type: p.type,
    categoryId: guessCategoryId(p, snap),
    walletId: guessWalletId(p, snap),
  );
}

/// Dompet yang disebut setelah atau tepat sebelum nominal; tidak disebut =
/// dompet pertama.
String guessWalletId(ParsedTx p, MoneySnapshot snap) {
  for (final text in [p.after.split(',').first, p.before.split(',').last]) {
    for (final w in snap.wallets) {
      if (_mentions(text, w.name)) return w.id;
    }
    if (_cashRe.hasMatch(text)) {
      for (final w in snap.wallets) {
        if (w.type == 'cash') return w.id;
      }
    }
  }
  return snap.wallets.first.id;
}

/// Urutan tebakan: transaksi lama dengan catatan sama, nama kategori yang
/// disebut, kata kunci kategori bawaan, "Lainnya", lalu kategori pertama.
String? guessCategoryId(ParsedTx p, MoneySnapshot snap) {
  bool usable(Category? c) =>
      c != null &&
      c.kind == p.type &&
      !c.isArchived &&
      !(snap.parentOf(c)?.isArchived ?? false);

  final note = p.note.toLowerCase();
  if (note.isNotEmpty) {
    for (final t in snap.transactions) {
      if (t.type == p.type &&
          t.note?.toLowerCase() == note &&
          usable(snap.categoryById[t.categoryId])) {
        return t.categoryId;
      }
    }
  }
  final roots = snap.categories.where((c) => c.kind == p.type).toList();
  final text = p.before.split(',').last;
  for (final root in roots) {
    for (final c in [...snap.childrenOf(root.id), root]) {
      if (_mentions('$note $text', c.name)) return c.id;
    }
  }
  final keywords = p.type == 'income' ? _incomeWords : _expenseWords;
  for (final MapEntry(key: systemKey, value: re) in keywords.entries) {
    if (!re.hasMatch('$note $text')) continue;
    for (final c in roots) {
      if (c.systemKey == systemKey) return c.id;
    }
  }
  final other = p.type == 'income' ? 'other_income' : 'other';
  for (final c in roots) {
    if (c.systemKey == other) return c.id;
  }
  return roots.isEmpty ? null : roots.first.id;
}

bool _mentions(String text, String name) {
  final n = name.trim().toLowerCase();
  return n.length > 1 &&
      RegExp(
        '(?<![\\p{L}\\p{N}])${RegExp.escape(n)}(?![\\p{L}\\p{N}])',
        unicode: true,
      ).hasMatch(text);
}

final _cashRe = RegExp(r'\b(cash|tunai)\b');

final _expenseWords = {
  'food': RegExp(
    r'\b(makan|sarapan|kopi|bakso|nasi|mie|jajan|minum|teh|roti|ayam|sate|'
    r'soto|warung|kafe|cemilan|snack|gorengan|seblak)\b',
  ),
  'transport': RegExp(
    r'\b(ojek|ojol|bensin|parkir|tol|kereta|krl|bus|angkot|taksi|grab|gojek|'
    r'servis)\b',
  ),
  'shopping': RegExp(
    r'\b(belanja|pasar|sayur|beras|sabun|baju|celana|sepatu|galon)\b',
  ),
  'bills': RegExp(r'\b(listrik|internet|wifi|pulsa|kuota|kos|kost|pdam)\b'),
  'entertainment': RegExp(r'\b(film|bioskop|nonton|game|langganan|konser)\b'),
};

final _incomeWords = {
  'salary': RegExp(r'\b(gaji|gajian)\b'),
  'bonus': RegExp(r'\b(bonus|thr|proyek)\b'),
};
