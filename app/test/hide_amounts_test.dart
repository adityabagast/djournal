import 'dart:async';

import 'package:djournal/core/format.dart';
import 'package:djournal/data/home_widget_sync.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/data/settings_repository.dart';
import 'package:djournal/features/settings/security_section.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings implements SettingsRepository {
  final _values = <String, String>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<String?> watch(String key) async* {
    yield _values[key];
    await for (final _ in _changes.stream) {
      yield _values[key];
    }
  }

  @override
  Future<void> set(String key, String value) async {
    _values[key] = value;
    _changes.add(null);
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
    _changes.add(null);
  }
}

void main() {
  group('format nominal masking', () {
    test('rupiah() dan signedRupiah() menghasilkan maskedRupiah saat hide = true', () {
      expect(rupiah(1250000, hide: true), maskedRupiah);
      expect(rupiah(1250000, hide: false), 'Rp 1.250.000');
      expect(signedRupiah(-35000, hide: true), maskedRupiah);
      expect(signedRupiah(-35000, hide: false), '−Rp 35.000');
      expect(signedRupiah(50000, hide: false, explicitPlus: true), '+Rp 50.000');
    });
  });

  testWidgets('toggle sembunyikan nominal di Pengaturan Keamanan', (tester) async {
    final settings = _FakeSettings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
        child: const MaterialApp(
          locale: Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SecuritySection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Sembunyikan nominal',
    );
    expect(switchFinder, findsOneWidget);

    // Bawaan: mati
    SwitchListTile switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isFalse);

    // Tap untuk aktifkan
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(settings._values['hide_amounts'], 'true');
    switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isTrue);

    // Tap lagi untuk nonaktifkan
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(settings._values['hide_amounts'], 'false');
    switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isFalse);
  });

  test('home widget menyembunyikan nominal saat hide = true', () {
    final l = lookupAppLocalizations(const Locale('id'));
    final snap = MoneySnapshot(
      wallets: [],
      categories: [],
      transactions: [],
      budgets: [],
    );
    final data = buildHomeWidgetData(
      snap: snap,
      entries: [],
      l: l,
      localeTag: 'id',
      hide: true,
      now: DateTime(2026, 10, 13),
    );

    expect(data['nw_hide'], '1');
    expect(data['nw_balance'], maskedRupiah);
    expect(data['nw_today_out'], maskedRupiah);
    expect(data['nw_budget_line'], '');
  });
}
