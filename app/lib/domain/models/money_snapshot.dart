import '../../data/db/app_database.dart';

/// Semua data keuangan dalam satu objek domain, plus perhitungan turunannya.
/// Saldo tidak pernah disimpan: selalu dihitung dari transaksi
/// (docs/data-model.md §4.1).
class MoneySnapshot {
  /// [wallets] dan [categories] berisi semua baris yang belum dihapus,
  /// termasuk yang diarsipkan/disembunyikan; snapshot memisahkannya sendiri.
  MoneySnapshot({
    required List<Wallet> wallets,
    required List<Category> categories,
    required this.transactions,
    this.budgets = const [],
  }) : wallets = wallets.where((w) => !w.isArchived).toList(),
       archivedWallets = wallets.where((w) => w.isArchived).toList(),
       categories = categories.where((c) => !c.isArchived).toList(),
       hiddenCategories = categories.where((c) => c.isArchived).toList(),
       walletById = {for (final w in wallets) w.id: w},
       categoryById = {for (final c in categories) c.id: c};

  /// Dompet aktif: tampil di daftar, pilihan dompet, dan total saldo.
  final List<Wallet> wallets;

  /// Dompet arsip: disembunyikan, tapi transaksinya tetap ada di riwayat
  /// dan laporan.
  final List<Wallet> archivedWallets;

  /// Kategori yang tampil di form catat transaksi, urut sesuai pilihan user.
  final List<Category> categories;

  /// Kategori yang disembunyikan dari form; transaksi lamanya tetap memakai
  /// kategori ini, jadi tetap ada di laporan.
  final List<Category> hiddenCategories;

  List<Category> get allCategories => [...categories, ...hiddenCategories];
  final List<Budget> budgets;

  /// Terbaru dulu.
  final List<MoneyTx> transactions;

  final Map<String, Wallet> walletById;
  final Map<String, Category> categoryById;

  int balanceOf(String walletId) {
    final w = walletById[walletId];
    var total = w?.openingBalance ?? 0;
    for (final t in transactions) {
      switch (t.type) {
        case 'income' when t.walletId == walletId:
          total += t.amount;
        case 'expense' when t.walletId == walletId:
          total -= t.amount;
        case 'transfer':
          if (t.walletId == walletId) total -= t.amount;
          if (t.toWalletId == walletId) total += t.amount;
      }
    }
    return total;
  }

  int get totalBalance => wallets.fold(0, (sum, w) => sum + balanceOf(w.id));

  Iterable<MoneyTx> onDate(String localDate) =>
      transactions.where((t) => t.localDate == localDate);

  Iterable<MoneyTx> inMonth(String monthKey) =>
      transactions.where((t) => t.localDate.startsWith(monthKey));

  static int sumOf(Iterable<MoneyTx> txs, String type) =>
      txs.where((t) => t.type == type).fold(0, (s, t) => s + t.amount);

  /// Budget yang berlaku untuk [monthKey] = baris dengan start_month
  /// terbesar yang ≤ bulan itu (docs/data-model.md §4.4). 0 = tanpa budget.
  int budgetFor(String categoryId, String monthKey) {
    Budget? best;
    for (final b in budgets) {
      if (b.categoryId != categoryId || b.startMonth.compareTo(monthKey) > 0) {
        continue;
      }
      if (best == null || b.startMonth.compareTo(best.startMonth) > 0) best = b;
    }
    return best?.amount ?? 0;
  }

  int totalBudget(String monthKey) => allCategories
      .where((c) => c.kind == 'expense')
      .fold(0, (sum, c) => sum + budgetFor(c.id, monthKey));

  int spentIn(String categoryId, String monthKey) =>
      inMonth(monthKey)
          .where((t) => t.type == 'expense' && t.categoryId == categoryId)
          .fold(0, (s, t) => s + t.amount);

  /// Total pengeluaran per kategori, terbesar dulu.
  List<(Category, int)> expenseByCategory(String monthKey) {
    final totals = <String, int>{};
    for (final t in inMonth(monthKey)) {
      if (t.type != 'expense' || t.categoryId == null) continue;
      totals[t.categoryId!] = (totals[t.categoryId!] ?? 0) + t.amount;
    }
    final rows = [
      for (final e in totals.entries)
        if (categoryById[e.key] case final c?) (c, e.value),
    ];
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    return rows;
  }
}

