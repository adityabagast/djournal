import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'db/app_database.dart';
import 'journal_repository.dart';
import 'money_snapshot.dart';
import 'security/lock_controller.dart';

/// Kelas AppWidgetProvider di android/app/src/main/kotlin/dev/nyawtat/app/widget/.
const homeWidgetProviders = [
  'dev.nyawtat.app.widget.RingkasWidget',
  'dev.nyawtat.app.widget.HariIniWidget',
  'dev.nyawtat.app.widget.CepatWidget',
];

const _masked = 'Rp •••••';

/// Isi widget layar utama dalam bentuk string yang sudah jadi (sudah
/// diterjemahkan dan diformat). Kotlin hanya menampilkannya, plus
/// menangani hari/bulan yang sudah berganti sejak data terakhir ditulis.
Map<String, String> buildHomeWidgetData({
  required MoneySnapshot snap,
  required List<JournalEntry> entries,
  required AppLocalizations l,
  required String localeTag,
  required bool hide,
  required DateTime now,
}) {
  final month = toMonthKey(now);
  final monthOut = MoneySnapshot.sumOf(snap.inMonth(month), 'expense');
  final todayOut = MoneySnapshot.sumOf(
    snap.onDate(toLocalDate(now)),
    'expense',
  );
  final budget = snap.totalBudget(month);
  final monthName = DateFormat('MMMM', localeTag).format(now);
  String money(int v) => hide ? _masked : rupiah(v);

  final balance = snap.totalBalance;
  final over = budget > 0 && monthOut > budget;

  // Widget jurnal hanya menampilkan jumlah dan jam, tidak pernah isi entri.
  final todayKeys = [
    for (final e in entries)
      if (e.entryDate == toLocalDate(now)) entrySortKey(e),
  ]..sort();
  return {
    'nw_date': toLocalDate(now),
    'nw_month': month,
    'nw_locale': localeTag,
    'nw_hide': hide ? '1' : '0',
    'nw_balance': hide
        ? _masked
        : '${balance < 0 ? '−' : ''}${rupiah(balance)}',
    'nw_today_out': money(todayOut),
    'nw_has_budget': budget > 0 ? '1' : '0',
    'nw_budget_pct': budget > 0
        ? '${(monthOut * 100 / budget).round().clamp(0, 100)}'
        : '0',
    'nw_budget_over': over ? '1' : '0',
    'nw_budget_line': budget == 0
        ? ''
        : over
        ? l.widgetBudgetOver(monthName, money(monthOut - budget))
        : l.budgetUsage(
            monthName,
            (monthOut * 100 / budget).round(),
            money(budget - monthOut),
          ),
    'nw_l_balance': l.widgetBalance,
    'nw_l_today_out': l.widgetTodayOut,
    'nw_l_today_suffix': l.widgetTodaySuffix,
    'nw_l_record': l.record,
    'nw_l_write': l.write,
    'nw_j_count': '${todayKeys.length}',
    'nw_j_sub': todayKeys.isEmpty
        ? ''
        : l.widgetJournalSummary(todayKeys.length, todayKeys.last),
    'nw_l_j_title': l.widgetJournalTitle,
    'nw_l_j_empty_title': l.widgetJournalEmptyTitle,
    'nw_l_j_empty_sub': l.widgetJournalEmptySub,
  };
}

/// Menulis ulang data widget setiap data keuangan, jurnal, status PIN, atau
/// bahasa berubah. Hanya aktif di Android.
final homeWidgetSyncProvider = Provider<void>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  Timer? debounce;
  Future<void> push() async {
    final snap = ref.read(moneySnapshotProvider).value;
    final entries = ref.read(journalEntriesProvider).value;
    final lock = ref.read(lockProvider);
    final locale = ref.read(localeProvider).value;
    if (snap == null || entries == null || lock.loading || locale == null) {
      return;
    }

    final data = buildHomeWidgetData(
      snap: snap,
      entries: entries,
      l: lookupAppLocalizations(locale),
      localeTag: locale.languageCode,
      // Saat PIN aktif, nominal tidak boleh terlihat di layar utama.
      hide: lock.pinEnabled,
      now: DateTime.now(),
    );
    try {
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      for (final name in homeWidgetProviders) {
        await HomeWidget.updateWidget(qualifiedAndroidName: name);
      }
    } catch (e) {
      debugPrint('Gagal memperbarui widget: $e');
    }
  }

  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), push);
  }

  ref.listen(moneySnapshotProvider, (_, _) => schedule());
  ref.listen(journalEntriesProvider, (_, _) => schedule());
  ref.listen(
    lockProvider.select((s) => (s.loading, s.pinEnabled)),
    (_, _) => schedule(),
  );
  ref.listen(localeProvider, (_, _) => schedule());
  ref.onDispose(() => debounce?.cancel());
  schedule();
});
