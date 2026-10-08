import 'package:excel/excel.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../ui/common.dart' show categoryLabel;
import '../ui/mood.dart' show moodLabel;
import 'db/app_database.dart';
import 'journal_repository.dart';
import 'money_snapshot.dart';

/// Laporan Excel untuk dibaca manusia (bukan untuk dipulihkan; itu tugas
/// backup JSON). Satu file, empat sheet: Transaksi, Jurnal, Dompet, Budget.
List<int> buildExcelReport({
  required AppLocalizations l,
  required MoneySnapshot money,
  required List<JournalEntry> entries,
  required DateTime now,
}) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet()!;

  final header = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#DCEBE4'),
  );
  final rupiahStyle = CellStyle(
    numberFormat: NumFormat.custom(formatCode: '"Rp "#,##0;-"Rp "#,##0'),
  );
  final dateStyle = CellStyle(numberFormat: NumFormat.defaultDate);

  Sheet addSheet(String name, List<String> columns, List<double> widths) {
    final sheet = excel[name];
    sheet.appendRow([for (final c in columns) TextCellValue(c)]);
    for (var i = 0; i < columns.length; i++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
              .cellStyle =
          header;
      sheet.setColumnWidth(i, widths[i]);
    }
    return sheet;
  }

  void style(Sheet sheet, int column, CellStyle s) {
    final row = sheet.maxRows - 1;
    sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
            )
            .cellStyle =
        s;
  }

  CellValue date(String ymd) {
    final d = parseLocalDate(ymd);
    return DateCellValue(year: d.year, month: d.month, day: d.day);
  }

  TextCellValue text(String? s) => TextCellValue(s ?? '');

  // Transaksi: terlama dulu; pengeluaran negatif supaya bisa dijumlah.
  final txSheet = addSheet(
    l.sheetTransactions,
    [
      l.csvDate,
      l.csvTime,
      l.csvType,
      l.category,
      l.wallet,
      l.csvToWallet,
      l.amount,
      l.note,
    ],
    [14, 8, 14, 16, 16, 16, 18, 40],
  );
  for (final t in money.transactions.reversed) {
    final cat = t.categoryId == null ? null : money.categoryById[t.categoryId];
    txSheet.appendRow([
      date(t.localDate),
      text(hhmm(t.occurredAt)),
      text(switch (t.type) {
        'expense' => l.expense,
        'income' => l.income,
        _ => l.transfer,
      }),
      text(cat == null ? null : categoryLabel(l, cat)),
      text(money.walletById[t.walletId]?.name),
      text(t.toWalletId == null ? null : money.walletById[t.toWalletId]?.name),
      IntCellValue(t.type == 'expense' ? -t.amount : t.amount),
      text(t.note),
    ]);
    style(txSheet, 0, dateStyle);
    style(txSheet, 6, rupiahStyle);
  }

  // Jurnal: terlama dulu, urut jam di dalam satu hari.
  final journal = addSheet(
    l.navJournal,
    [l.csvDate, l.csvTime, l.mood, l.entryTitle, l.story, l.tags],
    [14, 8, 10, 30, 60, 20],
  );
  final sorted = [...entries]
    ..sort((a, b) {
      final byDate = a.entryDate.compareTo(b.entryDate);
      return byDate != 0 ? byDate : entrySortKey(a).compareTo(entrySortKey(b));
    });
  for (final e in sorted) {
    journal.appendRow([
      date(e.entryDate),
      text(e.entryTime),
      text(e.mood == null ? null : moodLabel(l, e.mood!)),
      text(e.title),
      text(e.body),
      text(entryTags(e).join(', ')),
    ]);
    style(journal, 0, dateStyle);
  }

  // Dompet: saldo awal dan saldo sekarang.
  final walletSheet = addSheet(
    l.wallets,
    [l.walletName, l.walletType, l.openingBalance, l.currentBalance],
    [20, 12, 18, 18],
  );
  for (final w in money.wallets) {
    walletSheet.appendRow([
      text(w.name),
      text(switch (w.type) {
        'cash' => l.walletTypeCash,
        'bank' => l.walletTypeBank,
        'ewallet' => l.walletTypeEwallet,
        _ => l.walletTypeOther,
      }),
      IntCellValue(w.openingBalance),
      IntCellValue(money.balanceOf(w.id)),
    ]);
    style(walletSheet, 2, rupiahStyle);
    style(walletSheet, 3, rupiahStyle);
  }

  // Budget bulan ini per kategori pengeluaran.
  final monthKey = toMonthKey(now);
  final budgetSheet = addSheet(
    l.budget,
    [l.category, l.budgetLimit, l.spent, l.remaining],
    [18, 18, 18, 18],
  );
  for (final c in money.categories.where((c) => c.kind == 'expense')) {
    final limit = money.budgetFor(c.id, monthKey);
    final spent = money.spentIn(c.id, monthKey);
    if (limit == 0 && spent == 0) continue;
    budgetSheet.appendRow([
      text(categoryLabel(l, c)),
      IntCellValue(limit),
      IntCellValue(spent),
      IntCellValue(limit - spent),
    ]);
    for (final col in [1, 2, 3]) {
      style(budgetSheet, col, rupiahStyle);
    }
  }

  // Buang sheet kosong bawaan dan jadikan Transaksi sheet pertama.
  excel.setDefaultSheet(l.sheetTransactions);
  excel.delete(defaultSheet);

  return excel.encode()!;
}
