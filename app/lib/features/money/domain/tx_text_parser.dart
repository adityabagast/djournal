/// Mengenali transaksi (nama + nominal) di cerita jurnal berbahasa Indonesia,
/// sepenuhnya di perangkat. Murni Dart, tanpa dependensi Flutter.
library;

class ParsedTx {
  const ParsedTx({
    required this.key,
    required this.note,
    required this.amount,
    required this.type,
    required this.before,
    required this.after,
  });

  /// Nominal + urutannya di teks, supaya pilihan user tidak hilang saat kata
  /// di sekitarnya diedit.
  final String key;

  /// Tebakan catatan; kosong kalau tidak ada kata yang tersisa.
  final String note;

  /// Rupiah, selalu positif.
  final int amount;

  /// expense | income
  final String type;

  /// Teks sekitar nominal (huruf kecil), untuk menebak kategori dan dompet.
  final String before;
  final String after;
}

/// Nominal di bawah ini dianggap bukan uang ("beli 3", "lari 100").
const _minAmount = 500;

/// Batas aman: nominal salah ketik tidak boleh meluap.
const _maxAmount = 999999999999;

final _sentenceRe = RegExp(r'(?<=[.!?])\s+|\n+');
final _amountRe = RegExp(
  r'(rp\.?\s*)?(?<![\d.,])(\d+(?:[.,]\d+)*)\s*(ribu|rb|k|juta|jt)?(?![a-z0-9])',
  caseSensitive: false,
);
final _groupedRe = RegExp(r'^\d{1,3}(\.\d{3})+$');
final _digitsRe = RegExp(r'^\d+$');
final _thousandDotRe = RegExp(r'\.(?=\d{3}(?!\d))');

/// Kalimat rencana, harga, atau potongan: bukan uang yang benar-benar keluar.
final _skipRe = RegExp(
  r'\b(mau|pengen|ingin|rencana|besok|lusa|nanti|harga|harganya|hampir|kalau|'
  r'kalo|diskon|hemat|budget|target|gak jadi|nggak jadi|tidak jadi|batal)\b',
);
final _incomeRe = RegExp(
  r'\b(gaji|gajian|bonus|thr|terima|diterima|dapat|dapet|dikasih|refund|'
  r'dibayar)\b',
);
final _buyRe = RegExp(r'\b(?:beli|bayar|jajan|isi|pesan|top ?up)\s+');
final _partRe = RegExp(r',|;|\bdan\b|\bterus\b|\blalu\b', caseSensitive: false);
final _tailRe = RegExp(
  r'\b(?:sama|bareng|dengan|di|ke|pakai|pake|via|buat|untuk|seharga|habis|'
  r'abis)\b',
  caseSensitive: false,
);
final _punctRe = RegExp(r'[.!?:()"]');
final _spaceRe = RegExp(r'\s+');

const _noise = {
  'aku', 'saya', 'gue', 'gw', 'kita', 'tadi', 'barusan', 'habis', 'abis',
  'cuma', 'sekitar', 'total', 'totalnya', 'seharga', 'itu', 'ini', 'yang',
  'dan', 'terus', 'lalu', 'juga', 'jadi', 'dapat', 'dapet', 'terima',
  'dikasih', 'dibayar', 'rp', 'seharian', 'hari', 'akhirnya', 'masuk',
};

/// Semua transaksi yang disebut di [text], urut kemunculan.
List<ParsedTx> parseTxText(String text) {
  final out = <ParsedTx>[];
  final seen = <int, int>{};
  for (final sentence in text.split(_sentenceRe)) {
    final low = sentence.toLowerCase();
    if (_skipRe.hasMatch(low)) continue;
    final hits = [
      for (final m in _amountRe.allMatches(sentence))
        if (_amountOf(m) case final v?) (m.start, m.end, v),
    ];
    final income = _incomeRe.hasMatch(low) && !_buyRe.hasMatch(low);
    var from = 0;
    for (final (i, (start, end, amount)) in hits.indexed) {
      final before = sentence.substring(from, start);
      final next = i + 1 < hits.length ? hits[i + 1].$1 : sentence.length;
      final n = seen[amount] = (seen[amount] ?? 0) + 1;
      out.add(
        ParsedTx(
          key: '$amount#$n',
          note: _noteOf(before),
          amount: amount,
          type: income ? 'income' : 'expense',
          before: before.toLowerCase(),
          after: sentence.substring(end, next).toLowerCase(),
        ),
      );
      from = end;
    }
  }
  return out;
}

/// Nominal Rupiah dari satu kecocokan, atau null kalau bukan uang.
int? _amountOf(RegExpMatch m) {
  final hasRp = m.group(1) != null;
  final raw = m.group(2)!;
  final unit = m.group(3)?.toLowerCase();
  num? value;
  if (unit != null) {
    final n = num.tryParse(
      raw.replaceAll(_thousandDotRe, '').replaceAll(',', '.'),
    );
    final scale = unit == 'juta' || unit == 'jt' ? 1000000 : 1000;
    value = n == null ? null : n * scale;
  } else if (_groupedRe.hasMatch(raw)) {
    value = int.tryParse(raw.replaceAll('.', ''));
  } else if (_digitsRe.hasMatch(raw) &&
      // Angka polos: butuh "Rp" atau 5–9 digit (bukan tahun / nomor telepon).
      (hasRp || (raw.length >= 5 && raw.length <= 9 && !raw.startsWith('0')))) {
    value = int.tryParse(raw);
  }
  if (value == null || value < _minAmount || value > _maxAmount) return null;
  return value.round();
}

/// Kata benda sebelum nominal: "Tadi beli bakso bareng teman, habis" → "Bakso".
String _noteOf(String before) {
  for (final part in before.split(_partRe).reversed) {
    final buy = _buyRe.firstMatch(part.toLowerCase());
    final rest = buy == null ? part : part.substring(buy.end);
    final head = rest.split(_tailRe).firstWhere(
      (s) => s.trim().isNotEmpty,
      orElse: () => '',
    );
    final words = head
        .replaceAll(_punctRe, ' ')
        .split(_spaceRe)
        .where((w) => w.isNotEmpty && !_noise.contains(w.toLowerCase()))
        .take(4)
        .join(' ');
    if (words.isNotEmpty) return words[0].toUpperCase() + words.substring(1);
  }
  return '';
}
