import 'dart:math';

import 'package:excel/excel.dart';

import '../../../core/format.dart';
import '../domain/backup_period.dart';
import '../../../l10n/app_localizations.dart';
import '../../journal/presentation/mood.dart' show moodLabel;
import '../../../core/database/app_database.dart';
import '../../journal/data/journal_repository.dart';
import '../../money/domain/money_snapshot.dart';
import '../../money/presentation/money_widgets.dart' show categoryLabel;
import 'backup_payload.dart';
import 'excel_ooxml.dart';

const _dataSheet = '_Data_Sistem';
const _calcSheet = '_Hitung';
const _rupiah = '"Rp "#,##0;-"Rp "#,##0;"Rp "0';

/// Seperti [_rupiah] tapi nol dikosongkan (kolom Masuk/Keluar).
const _rupiahOrBlank = '"Rp "#,##0;-"Rp "#,##0;';
const _hero = '1F5F4E';
const _income = '17624A';
const _expense = 'A3401C';
const _gray = 'B8BFC6';
const _donutColors = [_hero, _expense, 'C9962B', '3F7CAC', '7A5C99', _gray];
const _pathSeparator = ' › ';

/// Laporan Excel untuk dibaca dan dianalisis: Ringkasan, Transaksi, Jurnal,
/// Dompet, Budget, dengan filter, chart, dan rumus. [rawBackupJson] disimpan
/// di sheet tersembunyi untuk pemulihan (lihat backup_payload.dart).
List<int> buildExcelReport({
  required AppLocalizations l,
  required MoneySnapshot money,
  required List<JournalEntry> entries,
  required DateTime now,
  BackupPeriod? period,
  String? rawBackupJson,
}) => _Report(l, money, entries, now, period).build(rawBackupJson);

/// Ekstrak kembali data JSON cadangan dari sheet `_Data_Sistem`.
String? extractRawBackupJsonFromExcel(List<int> bytes) {
  try {
    final sheet = Excel.decodeBytes(bytes).tables[_dataSheet];
    if (sheet == null) return null;
    return decodeBackupPayload([
      for (final row in sheet.rows)
        if (row.isNotEmpty) row.first?.value?.toString() ?? '',
    ]);
  } catch (_) {
    return null;
  }
}

/// Tanggal → nomor seri Excel.
int _serial(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1899, 12, 30)).inDays;

DateCellValue _dateCell(DateTime d) =>
    DateCellValue(year: d.year, month: d.month, day: d.day);

/// Teks user yang aman ditulis: tanpa karakter kontrol (membuat XML rusak)
/// dan tidak melewati batas 32.767 karakter per sel.
String _clean(String? s) {
  final t = (s ?? '').replaceAll(
    RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F￾￿]'),
    '',
  );
  if (t.length <= 32000) return t;
  // Jangan memotong di tengah pasangan surrogate (emoji).
  final cut = t.codeUnitAt(31999) & 0xFC00 == 0xD800 ? 31999 : 32000;
  return '${t.substring(0, cut)}…';
}

/// Nama yang ditafsirkan khusus oleh `SUMIFS`: wildcard (`*`, `?`, `~`),
/// operator, atau mirip angka/tanggal. Dicocokkan dengan `SUMPRODUCT`.
/// (`~~` di `SUMIFS` terbukti tidak cocok dengan `~` di Excel.)
bool _needsExactMatch(String name) =>
    RegExp(r'[*?~]|^[<>=\d+\-.,(%]').hasMatch(name);

CellStyle _style({
  String? format,
  String? dateFormat,
  bool bold = false,
  bool italic = false,
  String? color,
  String? fill,
  bool right = false,
  bool wrap = false,
  bool top = false,
  int? size,
}) => CellStyle(
  fontFamily: 'Arial',
  fontSize: size ?? 10,
  bold: bold,
  italic: italic,
  fontColorHex: ExcelColor.fromHexString('FF${color ?? '000000'}'),
  backgroundColorHex: fill == null
      ? ExcelColor.none
      : ExcelColor.fromHexString('FF$fill'),
  horizontalAlign: right ? HorizontalAlign.Right : HorizontalAlign.Left,
  verticalAlign: top ? VerticalAlign.Top : VerticalAlign.Center,
  textWrapping: wrap ? TextWrapping.WrapText : null,
  numberFormat: format != null
      ? NumFormat.custom(formatCode: format)
      : dateFormat != null
      ? CustomDateTimeNumFormat(formatCode: dateFormat)
      : NumFormat.standard_0,
);

/// Satu sheet: menulis sel dan mencatat nilai setiap rumus.
class _Sheet {
  _Sheet(Excel excel, this.name, List<double> widths) : _s = excel[name] {
    for (var i = 0; i < widths.length; i++) {
      _s.setColumnWidth(i, widths[i]);
    }
  }

  final String name;
  final Sheet _s;
  final cached = <String, Object>{};

  static final _plain = _style();

  void put(String ref, CellValue value, [CellStyle? style]) {
    // Sel angka/tanggal tanpa gaya dibiarkan memakai format bawaannya.
    _s.updateCell(
      CellIndex.indexByString(ref),
      value,
      cellStyle: style ?? (value is TextCellValue ? _plain : null),
    );
  }

  void text(String ref, String? value, [CellStyle? style]) {
    final t = _clean(value);
    if (t.isNotEmpty) put(ref, TextCellValue(t), style);
  }

  void formula(String ref, String f, Object value, CellStyle style) {
    put(ref, FormulaCellValue(f), style);
    cached[ref] = value;
  }

  void header(int row, List<String> labels, {Set<int> right = const {}, int firstColumn = 0}) {
    for (var i = 0; i < labels.length; i++) {
      final column = String.fromCharCode(65 + firstColumn + i);
      text(
        '$column$row',
        labels[i],
        _style(bold: true, color: _hero, fill: 'DCEBE4', right: right.contains(i)),
      );
    }
  }

  String abs(String ref) => absoluteRef(name, ref);
}

/// Baris Transaksi yang sudah disiapkan untuk rumus dan nilainya.
class _Tx {
  _Tx(this.tx, this.date, this.path, this.walletName, this.toWalletName);

  final MoneyTx tx;
  final DateTime date;
  final String path;
  final String walletName;
  final String toWalletName;

  String get root {
    final i = path.indexOf(_pathSeparator);
    return i < 0 ? path : path.substring(0, i);
  }

  int get inAmount => tx.type == 'income' ? tx.amount : 0;
  int get outAmount => tx.type == 'expense' ? tx.amount : 0;

  /// Pengeluaran negatif supaya kolom Nominal bisa dijumlah.
  int get signed => tx.type == 'expense' ? -tx.amount : tx.amount;
  bool inMonth(DateTime m) => date.year == m.year && date.month == m.month;
}

class _Report {
  _Report(this.l, this.money, List<JournalEntry> entries, this.now, this.period) {
    final all = period == null || period!.type == BackupPeriodType.all;
    whole = all;
    _nameWallets();
    _nameCategories();
    txs = [
      for (final t in money.transactions.reversed)
        if (all || period!.includesYmd(t.localDate)) _toRow(t),
    ];
    journal = [
      for (final e in entries)
        if (all || period!.includesYmd(e.entryDate)) e,
    ]..sort((a, b) {
        final byDate = a.entryDate.compareTo(b.entryDate);
        return byDate != 0
            ? byDate
            : entrySortKey(a).compareTo(entrySortKey(b));
      });

    final end = period?.endDate;
    asOf = all || end == null || end.isAfter(now) ? now : end;
    final dates = [
      DateTime(asOf.year, asOf.month),
      for (final t in txs) t.date,
      for (final e in journal) parseLocalDate(e.entryDate),
    ]..sort();
    for (
      var m = DateTime(dates.first.year, dates.first.month);
      !m.isAfter(dates.last);
      m = DateTime(m.year, m.month + 1)
    ) {
      months.add(m);
    }
    month = DateTime(asOf.year, asOf.month);
  }

  final AppLocalizations l;
  final MoneySnapshot money;
  final DateTime now;
  final BackupPeriod? period;

  late final bool whole;
  late final List<_Tx> txs;
  late final List<JournalEntry> journal;
  late final DateTime asOf;

  /// Bulan awal di dropdown.
  late final DateTime month;
  final months = <DateTime>[];
  final walletNames = <String, String>{};
  final rootNames = <String, String>{};

  final excel = Excel.createExcel();
  late final _Sheet summary, tx, diary, wallets, budget, calc;

  final moneyStyle = _style(format: _rupiah, right: true);
  final moneyBold = _style(format: _rupiah, right: true, bold: true);
  final dateStyle = _style(dateFormat: 'dd/mm/yyyy');
  final bold = _style(bold: true);

  bool get _id => l.localeName.startsWith('id');
  String get _monthFormat => _id ? '[\$-421]mmm yyyy' : '[\$-409]mmm yyyy';
  String get _monthShort => _id ? '[\$-421]mmm yy' : '[\$-409]mmm yy';
  String get _axisFormat =>
      '0.0,,"${l.xlMillion}";-0.0,,"${l.xlMillion}";0';

  /// Baris data Transaksi: 4 s.d. [lastTx].
  int get lastTx => max(4, txs.length + 3);
  String col(String c) => tx.abs('${c}4:$c$lastTx');

  /// Nama kembar diberi nomor, karena rumus mencocokkan nama.
  void _nameWallets() {
    final used = <String>{};
    for (final w in [...money.wallets, ...money.archivedWallets]) {
      walletNames[w.id] = _unique(_clean(w.name), used);
    }
  }

  /// Unik per jenis saja: kategori pengeluaran dan pemasukan yang senama
  /// (mis. "Lainnya") tidak saling mengganggu.
  void _nameCategories() {
    final used = <String, Set<String>>{};
    for (final c in money.allCategories) {
      rootNames[c.id] = _unique(
        _label(c),
        used.putIfAbsent(c.kind, () => {}),
      );
    }
  }

  String _label(Category c) =>
      _clean(categoryLabel(l, c)).replaceAll(_pathSeparator, ' > ');

  static String _unique(String base, Set<String> used) {
    var name = base;
    for (var n = 2; !used.add(name.trim().toLowerCase()); n++) {
      name = '$base ($n)';
    }
    return name;
  }

  String _path(Category c) {
    final parent = money.parentOf(c);
    return parent == null
        ? rootNames[c.id] ?? _label(c)
        : '${rootNames[parent.id] ?? _label(parent)}'
              '$_pathSeparator${_label(c)}';
  }

  _Tx _toRow(MoneyTx t) {
    final cat = t.categoryId == null ? null : money.categoryById[t.categoryId];
    return _Tx(
      t,
      parseLocalDate(t.localDate),
      cat == null ? '' : _path(cat),
      walletNames[t.walletId] ?? '',
      walletNames[t.toWalletId] ?? '',
    );
  }

  List<int> build(String? rawBackupJson) {
    final defaultSheet = excel.getDefaultSheet()!;
    summary = _Sheet(excel, l.xlSheetSummary, [34, 20, 20, 20, 3, 26, 18, 10, 3]);
    tx = _Sheet(
      excel,
      l.sheetTransactions,
      [12, 8, 14, 26, 18, 18, 17, 17, 17, 40, 18],
    );
    diary = _Sheet(excel, l.navJournal, [12, 8, 10, 30, 70, 20]);
    wallets = _Sheet(excel, l.wallets, [24, 14, 22, 18, 22]);
    budget = _Sheet(excel, l.budget, [28, 18, 18, 18, 14]);
    calc = _Sheet(excel, _calcSheet, [24, 18, 18]);

    _buildTransactions();
    final diaryLast = _buildJournal();
    final walletTotal = _buildWallets();
    final budgetLast = _buildBudget();
    final summaryCharts = _buildSummary(walletTotal, diaryLast);
    if (rawBackupJson != null) {
      final data = excel[_dataSheet];
      final cells = encodeBackupPayload(rawBackupJson);
      for (var i = 0; i < cells.length; i++) {
        data.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i),
          TextCellValue(cells[i]),
        );
      }
    }

    excel.setDefaultSheet(summary.name);
    excel.delete(defaultSheet);

    return enrichXlsx(excel.encode()!, {
      summary.name: SheetExtras(
        showGridLines: false,
        rowHeight: 20,
        dropdowns: {'B4': '\$A\$16:\$A\$${15 + months.length}'},
        cached: summary.cached,
        charts: summaryCharts,
      ),
      tx.name: SheetExtras(
        freezeRows: 3,
        autoFilter: 'A3:K$lastTx',
        cached: tx.cached,
      ),
      diary.name: SheetExtras(freezeRows: 1, autoFilter: 'A1:F$diaryLast'),
      wallets.name: SheetExtras(
        freezeRows: 1,
        cached: wallets.cached,
        charts: _walletCharts(walletTotal - 1),
      ),
      budget.name: SheetExtras(
        freezeRows: 3,
        autoFilter: 'A3:E$budgetLast',
        highlights: {'A4:E$budgetLast': r'AND($B4>0,$C4>$B4)'},
        cached: budget.cached,
        charts: _budgetCharts(budgetLast),
      ),
      _calcSheet: SheetExtras(hidden: true, cached: calc.cached),
      _dataSheet: const SheetExtras(hidden: true),
    });
  }

  // ── Transaksi ──────────────────────────────────────────────────────────

  void _buildTransactions() {
    tx.header(
      3,
      [
        l.csvDate, l.csvTime, l.csvType, l.category, l.wallet, l.csvToWallet,
        l.amount, l.xlIn, l.xlOut, l.note, l.xlMainCategory,
      ],
      right: {6, 7, 8},
    );
    final inStyle = _style(format: _rupiahOrBlank, right: true, color: _income);
    final outStyle = _style(format: _rupiahOrBlank, right: true, color: _expense);
    final plain = _style();

    for (var i = 0; i < txs.length; i++) {
      final t = txs[i];
      final r = i + 4;
      tx.put('A$r', _dateCell(t.date), dateStyle);
      tx.text('B$r', hhmm(t.tx.occurredAt));
      tx.text('C$r', switch (t.tx.type) {
        'expense' => l.expense,
        'income' => l.income,
        _ => l.transfer,
      });
      tx.text('D$r', t.path);
      tx.text('E$r', t.walletName);
      tx.text('F$r', t.toWalletName);
      tx.put('G$r', IntCellValue(t.signed), moneyStyle);
      tx.formula('H$r', 'IF(C$r="${l.income}",G$r,0)', t.inAmount, inStyle);
      tx.formula('I$r', 'IF(C$r="${l.expense}",-G$r,0)', t.outAmount, outStyle);
      tx.text('J$r', t.tx.note);
      tx.formula(
        'K$r',
        'IFERROR(LEFT(D$r,FIND("$_pathSeparator",D$r)-1),D$r&"")',
        t.root,
        plain,
      );
    }

    final totalIn = _sum(txs, (t) => t.inAmount);
    final totalOut = _sum(txs, (t) => t.outAmount);
    tx.text('A1', l.xlFilterTotal, bold);
    tx.formula('G1', 'H1-I1', totalIn - totalOut, moneyBold);
    tx.formula('H1', 'SUBTOTAL(109,H4:H$lastTx)', totalIn, moneyBold);
    tx.formula('I1', 'SUBTOTAL(109,I4:I$lastTx)', totalOut, moneyBold);
  }

  static int _sum(Iterable<_Tx> list, int Function(_Tx) f) =>
      list.fold(0, (s, t) => s + f(t));

  // ── Jurnal ─────────────────────────────────────────────────────────────

  int _buildJournal() {
    diary.header(1, [
      l.csvDate, l.csvTime, l.mood, l.entryTitle, l.story, l.tags,
    ]);
    final top = _style(top: true);
    final wrap = _style(top: true, wrap: true);
    final date = _style(dateFormat: 'dd/mm/yyyy', top: true);
    for (var i = 0; i < journal.length; i++) {
      final e = journal[i];
      final r = i + 2;
      diary.put('A$r', _dateCell(parseLocalDate(e.entryDate)), date);
      diary.text('B$r', e.entryTime, top);
      diary.text('C$r', e.mood == null ? null : moodLabel(l, e.mood!), top);
      diary.text('D$r', e.title, wrap);
      diary.text('E$r', e.body, wrap);
      diary.text('F$r', entryTags(e).join(', '), top);
    }
    return max(2, journal.length + 1);
  }

  // ── Dompet ─────────────────────────────────────────────────────────────

  final _walletLabels = <String>[];
  final _walletEnds = <int>[];

  /// Mengembalikan nomor baris total.
  int _buildWallets() {
    wallets.header(
      1,
      [
        l.walletName,
        l.walletType,
        whole ? l.openingBalance : l.xlBalanceBefore,
        l.xlChange,
        whole ? l.currentBalance : l.xlBalanceEnd,
      ],
      right: {2, 3, 4},
    );
    final list = [...money.wallets, ...money.archivedWallets];
    var totalOpening = 0, totalChange = 0;
    for (var i = 0; i < list.length; i++) {
      final w = list[i];
      final r = i + 2;
      final name = walletNames[w.id]!;
      final opening = w.openingBalance + _changeBefore(w.id);
      final change = _change(w.id, txs.map((t) => t.tx));
      wallets.text('A$r', name);
      wallets.text('B$r', switch (w.type) {
        'cash' => l.walletTypeCash,
        'bank' => l.walletTypeBank,
        'ewallet' => l.walletTypeEwallet,
        _ => l.walletTypeOther,
      });
      wallets.put('C$r', IntCellValue(opening), moneyStyle);
      String part(String walletCol, String op) => _needsExactMatch(name)
          ? 'SUMPRODUCT((${col(walletCol)}=A$r)*'
                '(${col('C')}$op"${l.transfer}")*${col('G')})'
          : 'SUMIFS(${col('G')},${col(walletCol)},A$r,'
                '${col('C')},"${op == '=' ? '' : op}${l.transfer}")';
      wallets.formula(
        'D$r',
        '${part('E', '<>')}-${part('E', '=')}+${part('F', '=')}',
        change,
        moneyStyle,
      );
      wallets.formula('E$r', 'C$r+D$r', opening + change, moneyStyle);
      totalOpening += opening;
      totalChange += change;
      _walletLabels.add(name);
      _walletEnds.add(opening + change);
    }
    final last = max(2, list.length + 1);
    final total = last + 1;
    wallets.text('A$total', l.xlTotal, bold);
    wallets.formula('C$total', 'SUM(C2:C$last)', totalOpening, moneyBold);
    wallets.formula('D$total', 'SUM(D2:D$last)', totalChange, moneyBold);
    wallets.formula(
      'E$total',
      'SUM(E2:E$last)',
      totalOpening + totalChange,
      moneyBold,
    );
    return total;
  }

  int _change(String walletId, Iterable<MoneyTx> list) {
    var total = 0;
    for (final t in list) {
      if (t.walletId == walletId) {
        total += t.type == 'income' ? t.amount : -t.amount;
      }
      if (t.type == 'transfer' && t.toWalletId == walletId) total += t.amount;
    }
    return total;
  }

  /// Perubahan saldo sebelum periode, supaya saldo akhir tetap benar walau
  /// transaksi lama tidak ada di tabel.
  int _changeBefore(String walletId) {
    final start = whole ? null : period!.startDate;
    if (start == null) return 0;
    return _change(
      walletId,
      money.transactions.where(
        (t) => parseLocalDate(t.localDate).isBefore(start),
      ),
    );
  }

  List<ChartSpec> _walletCharts(int last) => [
    if (_walletLabels.isNotEmpty)
      ChartSpec(
        type: ChartType.bar,
        title: l.xlChartWallet,
        categoryRef: wallets.abs('A2:A$last'),
        categories: _walletLabels,
        series: [
          ChartSeries(
            name: l.xlChartWallet,
            ref: wallets.abs('E2:E$last'),
            values: _walletEnds,
            color: _hero,
          ),
        ],
        column: 6,
        row: 1,
        width: 460,
        height: max(220, 60 + _walletLabels.length * 26),
        valueFormat: _axisFormat,
      ),
  ];

  // ── Budget ─────────────────────────────────────────────────────────────

  final _budgetLabels = <String>[];
  final _budgetLimits = <int>[];
  final _budgetSpent = <int>[];

  int _buildBudget() {
    final monthKey = toMonthKey(month);
    budget.text('A1', l.xlBudgetMonth, bold);
    budget.put('B1', _dateCell(month), _style(dateFormat: _monthFormat));
    budget.header(
      3,
      [l.category, l.budgetLimit, l.spent, l.remaining, l.xlUsedPercent],
      right: {1, 2, 3, 4},
    );
    final percent = _style(format: '0%', right: true);
    var r = 4;
    for (final c in money.allCategories.where((c) => c.kind == 'expense')) {
      final label = rootNames[c.id]!;
      final limit = money.budgetFor(c.id, monthKey);
      // Sama dengan rumusnya: semua baris bulan ini dengan kategori utama itu.
      final spent = _sum(
        txs.where((t) => t.inMonth(month) && _same(t.root, label)),
        (t) => t.outAmount,
      );
      if (limit == 0 && spent == 0) continue;
      budget.text('A$r', label);
      budget.put('B$r', IntCellValue(limit), moneyStyle);
      budget.formula(
        'C$r',
        _categorySum('A$r', label, r'$B$1'),
        spent,
        moneyStyle,
      );
      budget.formula(
        'D$r',
        'IF(B$r=0,"-",B$r-C$r)',
        limit == 0 ? '-' : limit - spent,
        moneyStyle,
      );
      budget.formula(
        'E$r',
        'IF(B$r=0,"-",C$r/B$r)',
        limit == 0 ? '-' : spent / limit,
        percent,
      );
      _budgetLabels.add(label);
      _budgetLimits.add(limit);
      _budgetSpent.add(spent);
      r++;
    }
    return max(4, r - 1);
  }

  /// `SUMIFS` tidak membedakan huruf besar/kecil.
  static bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();

  String _monthRange(String ref) =>
      '${col('A')},">="&$ref,${col('A')},"<"&EDATE($ref,1)';

  /// Pengeluaran kategori utama di sel [ref] selama bulan di sel [monthRef].
  String _categorySum(String ref, String name, String monthRef) =>
      _needsExactMatch(name)
      ? 'SUMPRODUCT((${col('K')}=$ref)*(${col('A')}>=$monthRef)*'
            '(${col('A')}<EDATE($monthRef,1))*${col('I')})'
      : 'SUMIFS(${col('I')},${col('K')},$ref,${_monthRange(monthRef)})';

  List<ChartSpec> _budgetCharts(int last) => [
    if (_budgetLabels.isNotEmpty)
      ChartSpec(
        type: ChartType.bar,
        title: l.xlChartBudget,
        categoryRef: budget.abs('A4:A$last'),
        categories: _budgetLabels,
        series: [
          ChartSeries(
            name: l.xlLimit,
            ref: budget.abs('B4:B$last'),
            values: _budgetLimits,
            color: _gray,
          ),
          ChartSeries(
            name: l.spent,
            ref: budget.abs('C4:C$last'),
            values: _budgetSpent,
            color: _expense,
          ),
        ],
        column: 6,
        row: 2,
        width: 480,
        height: max(240, 90 + _budgetLabels.length * 30),
        valueFormat: _axisFormat,
        legend: true,
      ),
  ];

  // ── Ringkasan ──────────────────────────────────────────────────────────

  List<ChartSpec> _buildSummary(int walletTotal, int diaryLast) {
    final monthStyle = _style(dateFormat: _monthFormat);
    final inMonth = txs.where((t) => t.inMonth(month)).toList();
    final income = _sum(inMonth, (t) => t.inAmount);
    final expense = _sum(inMonth, (t) => t.outAmount);
    final firstMonth = 16;
    final lastMonth = 15 + months.length;

    summary.text('A1', l.xlTitle, _style(bold: true, color: _hero, size: 14));
    summary.text('A2', l.xlAsOf);
    summary.put('B2', _dateCell(asOf), _style(dateFormat: 'dd/mm/yyyy', right: true));
    summary.text('A4', l.xlPickMonth, bold);
    summary.put(
      'B4',
      _dateCell(month),
      _style(dateFormat: _monthFormat, bold: true, fill: 'FFF6CC', right: true),
    );
    summary.text('C4', l.xlPickMonthHint, _style(italic: true, color: '6B7280'));

    summary.header(6, [l.xlSelectedMonth, l.xlValue], right: {1});
    final labels = [
      l.income, l.expense, l.xlNet, l.xlAvgPerDay, l.xlTxCount, l.xlTotalBalance,
    ];
    for (var i = 0; i < labels.length; i++) {
      summary.text('A${7 + i}', labels[i]);
    }
    final range = _monthRange(r'$B$4');
    CellStyle kpi(String? color) =>
        _style(format: _rupiah, right: true, bold: true, color: color);
    summary.formula('B7', 'SUMIFS(${col('H')},$range)', income, kpi(_income));
    summary.formula('B8', 'SUMIFS(${col('I')},$range)', expense, kpi(_expense));
    summary.formula('B9', 'B7-B8', income - expense, kpi(null));
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final days = min(monthEnd.day, asOf.day);
    summary.formula(
      'B10',
      'IF(MIN(EOMONTH(B4,0),B2)<B4,0,ROUND(B8/(MIN(EOMONTH(B4,0),B2)-B4+1),0))',
      (expense / days).round(),
      kpi(null),
    );
    summary.formula(
      'B11',
      'COUNTIFS($range)',
      inMonth.length,
      _style(format: '#,##0', right: true, bold: true),
    );
    summary.formula(
      'B12',
      wallets.abs('E$walletTotal'),
      _walletEnds.fold<int>(0, (s, v) => s + v),
      kpi(null),
    );

    summary.header(
      15,
      [l.xlPerMonth, l.income, l.expense, l.xlNet],
      right: {1, 2, 3},
    );
    final monthIn = <int>[], monthOut = <int>[];
    for (var i = 0; i < months.length; i++) {
      final r = firstMonth + i;
      final rows = txs.where((t) => t.inMonth(months[i])).toList();
      monthIn.add(_sum(rows, (t) => t.inAmount));
      monthOut.add(_sum(rows, (t) => t.outAmount));
      summary.put('A$r', _dateCell(months[i]), monthStyle);
      final m = _monthRange('\$A$r');
      summary.formula('B$r', 'SUMIFS(${col('H')},$m)', monthIn[i], moneyStyle);
      summary.formula('C$r', 'SUMIFS(${col('I')},$m)', monthOut[i], moneyStyle);
      summary.formula('D$r', 'B$r-C$r', monthIn[i] - monthOut[i], moneyStyle);
    }

    final top = _buildTopCategories(inMonth, expense);

    final moodRow = lastMonth + 3;
    summary.header(moodRow, [l.xlMoodOfMonth, l.xlEntryCount], right: {1});
    final moodNames = [for (var m = 1; m <= 5; m++) moodLabel(l, m)];
    final moodCounts = <int>[];
    final count = _style(format: '#,##0', right: true);
    final dMood = diary.abs('C2:C$diaryLast');
    final dDate = diary.abs('A2:A$diaryLast');
    for (var i = 0; i < 5; i++) {
      final r = moodRow + 1 + i;
      final n = journal.where((e) {
        final d = parseLocalDate(e.entryDate);
        return e.mood == i + 1 && d.year == month.year && d.month == month.month;
      }).length;
      moodCounts.add(n);
      summary.text('A$r', moodNames[i]);
      summary.formula(
        'B$r',
        'COUNTIFS($dMood,A$r,$dDate,">="&\$B\$4,$dDate,"<"&EDATE(\$B\$4,1))',
        n,
        count,
      );
    }

    // Chart per bulan hanya 12 bulan terakhir supaya tetap terbaca.
    final from = max(0, months.length - 12);
    final chartFirst = firstMonth + from;
    return [
      if (txs.isNotEmpty) ...[
        ChartSpec(
          type: ChartType.doughnut,
          title: l.xlChartCategory,
          categoryRef: summary.abs('F7:F12'),
          categories: [for (final t in top) t.$1],
          series: [
            ChartSeries(
              name: l.expense,
              ref: summary.abs('G7:G12'),
              values: [for (final t in top) t.$2],
              pointColors: _donutColors,
            ),
          ],
          column: 9,
          row: 1,
          width: 340,
          height: 225,
          legend: true,
        ),
        ChartSpec(
          type: ChartType.column,
          title: l.xlChartMonthly,
          categoryRef: summary.abs('A$chartFirst:A$lastMonth'),
          categories: [for (final m in months.skip(from)) _serial(m)],
          categoryFormat: _monthShort,
          series: [
            ChartSeries(
              name: l.income,
              ref: summary.abs('B$chartFirst:B$lastMonth'),
              values: monthIn.sublist(from),
              color: _income,
            ),
            ChartSeries(
              name: l.expense,
              ref: summary.abs('C$chartFirst:C$lastMonth'),
              values: monthOut.sublist(from),
              color: _expense,
            ),
          ],
          column: 5,
          row: 14,
          width: 640,
          height: 262,
          valueFormat: _axisFormat,
          legend: true,
        ),
      ],
      if (journal.any((e) => e.mood != null))
        ChartSpec(
          type: ChartType.column,
          title: l.xlChartMood,
          categoryRef: summary.abs('A${moodRow + 1}:A${moodRow + 5}'),
          categories: moodNames,
          series: [
            ChartSeries(
              name: l.xlEntryCount,
              ref: summary.abs('B${moodRow + 1}:B${moodRow + 5}'),
              values: moodCounts,
              color: _hero,
            ),
          ],
          column: 5,
          row: 29,
          width: 420,
          height: 220,
          valueFormat: '0',
          majorUnit: moodCounts.reduce(max) <= 8 ? 1 : null,
        ),
    ];
  }

  /// Lima kategori utama terbesar + gabungan sisanya. Daftar lengkapnya di
  /// sheet bantu supaya ikut berubah saat bulan diganti.
  List<(String, int)> _buildTopCategories(List<_Tx> inMonth, int expense) {
    calc.header(1, [l.category, l.amount, '#']);
    final names = <String>[];
    final seen = <String>{};
    for (final t in txs) {
      if (t.tx.type == 'expense' &&
          t.root.isNotEmpty &&
          seen.add(t.root.toLowerCase())) {
        names.add(t.root);
      }
    }
    final ranked = <(String, int, int)>[];
    for (var i = 0; i < names.length; i++) {
      final r = i + 2;
      final total = _sum(
        inMonth.where((t) => _same(t.root, names[i])),
        (t) => t.outAmount,
      );
      calc.text('A$r', names[i]);
      calc.formula(
        'B$r',
        _categorySum('A$r', names[i], summary.abs('B4')),
        total,
        moneyStyle,
      );
      // Pecahan kecil membuat jumlah yang sama tetap punya urutan.
      calc.formula('C$r', 'B$r+ROW()/10000', total + r / 10000, moneyStyle);
      ranked.add((names[i], total, r));
    }
    ranked.sort((a, b) => b.$2 != a.$2 ? b.$2 - a.$2 : b.$3 - a.$3);

    final last = max(2, names.length + 1);
    String calcCol(String c) => calc.abs('${c}2:$c$last');
    summary.header(
      6,
      [l.xlByCategory, l.amount, l.xlShare],
      right: {1, 2},
      firstColumn: 5,
    );
    final plain = _style();
    final percent = _style(format: '0.0%', right: true);
    final out = <(String, int)>[];
    for (var k = 1; k <= 5; k++) {
      final r = 6 + k;
      final hit = k <= ranked.length && ranked[k - 1].$2 > 0
          ? (ranked[k - 1].$1, ranked[k - 1].$2)
          : ('-', 0);
      final at = 'MATCH(LARGE(${calcCol('C')},$k),${calcCol('C')},0)';
      summary.formula(
        'G$r',
        'IFERROR(INDEX(${calcCol('B')},$at),0)',
        hit.$2,
        moneyStyle,
      );
      summary.formula(
        'F$r',
        'IF(G$r=0,"-",INDEX(${calcCol('A')},$at))',
        hit.$1,
        plain,
      );
      out.add(hit);
    }
    final rest = expense - out.fold<int>(0, (s, e) => s + e.$2);
    summary.text('F12', l.xlOthers);
    summary.formula('G12', r'$B$8-SUM(G7:G11)', rest, moneyStyle);
    out.add((l.xlOthers, rest));
    for (var i = 0; i < out.length; i++) {
      final r = 7 + i;
      summary.formula(
        'H$r',
        'IF(\$B\$8=0,0,G$r/\$B\$8)',
        expense == 0 ? 0 : out[i].$2 / expense,
        percent,
      );
    }
    return out;
  }
}
