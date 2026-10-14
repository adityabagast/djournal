import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../domain/models/money_snapshot.dart';
import 'database_providers.dart';

final walletsProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchWallets(),
);

final categoriesProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchCategories(),
);

final transactionsProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchTransactions(),
);

final budgetsProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchBudgets(),
);

/// Gabungan dompet + kategori + transaksi + budget. Ter-update otomatis
/// setiap ada perubahan di database.
final moneySnapshotProvider = Provider<AsyncValue<MoneySnapshot>>((ref) {
  final parts = [
    ref.watch(walletsProvider),
    ref.watch(categoriesProvider),
    ref.watch(transactionsProvider),
    ref.watch(budgetsProvider),
  ];
  for (final p in parts) {
    if (p.hasError) return AsyncValue.error(p.error!, p.stackTrace!);
  }
  final wallets = parts[0].value as List<Wallet>?;
  final categories = parts[1].value as List<Category>?;
  final txs = parts[2].value as List<MoneyTx>?;
  final budgets = parts[3].value as List<Budget>?;
  if (wallets == null || categories == null || txs == null || budgets == null) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(
    MoneySnapshot(
      wallets: wallets,
      categories: categories,
      transactions: txs,
      budgets: budgets,
    ),
  );
});

