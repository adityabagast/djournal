import 'dart:async';

import 'package:djournal/core/theme.dart';
import 'package:djournal/data/settings_repository.dart';
import 'package:djournal/features/settings/appearance_section.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pengganti tabel app_settings: tes widget dengan database drift asli macet.
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
  testWidgets('pilih Gelap lalu Terang mengganti tema app', (tester) async {
    final settings = _FakeSettings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: AppearanceSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color background() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(Scaffold),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;

    // Bawaan: ikut sistem (di tes = terang).
    expect(find.textContaining('Mengikuti mode gelap'), findsOneWidget);
    expect(background(), AppPalette.light.background);

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(settings._values['theme_mode'], 'dark');
    expect(find.textContaining('Selalu gelap'), findsOneWidget);
    expect(background(), AppPalette.dark.background);

    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();
    expect(settings._values['theme_mode'], 'light');
    expect(background(), AppPalette.light.background);
  });
}
