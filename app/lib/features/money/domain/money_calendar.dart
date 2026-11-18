import 'money_snapshot.dart';

class DayTotal {
  const DayTotal({this.income = 0, this.expense = 0});
  final int income;
  final int expense;
}

/// Total per tanggal ("YYYY-MM-DD") untuk satu bulan. Transfer tidak dihitung,
/// jadi hari yang isinya hanya transfer tidak masuk.
Map<String, DayTotal> dailyTotals(MoneySnapshot snap, String monthKey) {
  final totals = <String, DayTotal>{};
  for (final tx in snap.inMonth(monthKey)) {
    if (tx.type != 'income' && tx.type != 'expense') continue;
    final d = totals[tx.localDate] ?? const DayTotal();
    totals[tx.localDate] = tx.type == 'income'
        ? DayTotal(income: d.income + tx.amount, expense: d.expense)
        : DayTotal(income: d.income, expense: d.expense + tx.amount);
  }
  return totals;
}

/// 85000 -> "85rb", 8500000 -> "8,5jt". Tetap int, tanpa double.
String shortAmount(int n) {
  if (n < 1000) return '$n';
  final rb = (n + 500) ~/ 1000;
  if (rb < 1000) return '${rb}rb';
  final tenths = (n + 50000) ~/ 100000; // Dibulatkan ke 0,1 jt
  return tenths % 10 == 0
      ? '${tenths ~/ 10}jt'
      : '${tenths ~/ 10},${tenths % 10}jt';
}
