import '../core/format.dart';
import 'db/app_database.dart';
import 'journal_repository.dart';
import 'money_snapshot.dart';

enum SearchScope { all, journal, transactions }

enum SearchPeriod { all, thisMonth, threeMonths }

/// Satu hasil: entri jurnal atau transaksi.
class SearchHit {
  SearchHit.entry(JournalEntry this.entry)
    : tx = null,
      date = entry.entryDate,
      sortKey = '${entry.entryDate} ${entrySortKey(entry)}';

  SearchHit.tx(MoneyTx this.tx)
    : entry = null,
      date = tx.localDate,
      sortKey = '${tx.localDate} ${hhmm(tx.occurredAt)}';

  final JournalEntry? entry;
  final MoneyTx? tx;

  /// Tanggal lokal YYYY-MM-DD, untuk pengelompokan per hari.
  final String date;
  final String sortKey;
}

class SearchResults {
  const SearchResults({
    required this.hits,
    required this.entryCount,
    required this.txCount,
    required this.expense,
    required this.income,
  });

  /// Terbaru dulu.
  final List<SearchHit> hits;
  final int entryCount;
  final int txCount;
  final int expense;
  final int income;
}

/// Kata-kata pencarian, huruf kecil.
List<String> searchTerms(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// Cari di jurnal (judul, isi, tag) dan transaksi (catatan, kategori,
/// dompet, nominal). Semua kata harus cocok. Kata berupa angka (≥ 3 digit,
/// titik ribuan boleh) juga cocok dengan nominal transaksi.
SearchResults searchAll({
  required String query,
  required List<JournalEntry> entries,
  required MoneySnapshot money,
  required String Function(Category) categoryName,
  required String transferLabel,
  SearchScope scope = SearchScope.all,
  SearchPeriod period = SearchPeriod.all,
  DateTime? now,
}) {
  final terms = searchTerms(query);
  if (terms.isEmpty) {
    return const SearchResults(
      hits: [],
      entryCount: 0,
      txCount: 0,
      expense: 0,
      income: 0,
    );
  }
  final today = now ?? DateTime.now();
  final from = switch (period) {
    SearchPeriod.all => '',
    SearchPeriod.thisMonth => toLocalDate(DateTime(today.year, today.month)),
    SearchPeriod.threeMonths => toLocalDate(
      DateTime(today.year, today.month - 2),
    ),
  };

  bool matches(String haystack, [int? amount]) {
    final text = haystack.toLowerCase();
    for (final term in terms) {
      if (text.contains(term)) continue;
      final digits = term.replaceAll(RegExp(r'[.,]'), '');
      if (amount != null &&
          digits.length >= 3 &&
          RegExp(r'^\d+$').hasMatch(digits) &&
          '$amount'.contains(digits)) {
        continue;
      }
      return false;
    }
    return true;
  }

  final hits = <SearchHit>[];
  var entryCount = 0;
  var txCount = 0;
  var expense = 0;
  var income = 0;

  if (scope != SearchScope.transactions) {
    for (final e in entries) {
      if (e.entryDate.compareTo(from) < 0) continue;
      final haystack = [
        e.title ?? '',
        e.body ?? '',
        for (final tag in entryTags(e)) '#$tag',
      ].join(' ');
      if (!matches(haystack)) continue;
      hits.add(SearchHit.entry(e));
      entryCount++;
    }
  }
  if (scope != SearchScope.journal) {
    for (final t in money.transactions) {
      if (t.localDate.compareTo(from) < 0) continue;
      final category = money.categoryById[t.categoryId];
      final haystack = [
        t.note ?? '',
        if (category != null) categoryName(category),
        if (t.type == 'transfer') transferLabel,
        money.walletById[t.walletId]?.name ?? '',
        money.walletById[t.toWalletId]?.name ?? '',
      ].join(' ');
      if (!matches(haystack, t.amount)) continue;
      hits.add(SearchHit.tx(t));
      txCount++;
      if (t.type == 'expense') expense += t.amount;
      if (t.type == 'income') income += t.amount;
    }
  }
  hits.sort((a, b) => b.sortKey.compareTo(a.sortKey));
  return SearchResults(
    hits: hits,
    entryCount: entryCount,
    txCount: txCount,
    expense: expense,
    income: income,
  );
}
