import 'dart:async';
import 'dart:math' as math;

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

  testWidgets('pilih warna aksen mengganti warna aksen app', (tester) async {
    final settings = _FakeSettings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: buildTheme(
              Brightness.light,
              accent: AccentPresets.resolve(ref.watch(accentIdProvider).value),
            ),
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: AppearanceSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    AppPalette palette() => Theme.of(
      tester.element(find.byType(Scaffold)),
    ).extension<AppPalette>()!;

    // Bawaan: hijau sage.
    expect(palette().hero, AppColors.hero);
    expect(palette().primary, AppPalette.light.primary);

    await tester.tap(find.text('Biru laut'));
    await tester.pumpAndSettle();
    expect(settings._values['accent_color'], 'ocean');
    expect(palette().hero, AccentPresets.ocean.color);
    expect(
      palette().primary,
      AppPalette.light.withAccent(AccentPresets.ocean.color).primary,
    );
  });

  test('warna aksen diturunkan untuk mode terang dan gelap', () {
    for (final o in AccentPresets.all) {
      for (final base in [AppPalette.light, AppPalette.dark]) {
        final p = base.withAccent(o.color);
        expect(p.hero, o.color, reason: o.id);
        expect(p.isDark, base.isDark, reason: o.id);
        // Teks/ikon di atas primary harus kontras (rasio WCAG >= 3).
        final fg = readableOn(p.primary).computeLuminance();
        final bg = p.primary.computeLuminance();
        final ratio =
            (math.max(fg, bg) + 0.05) / (math.min(fg, bg) + 0.05);
        expect(ratio, greaterThan(3), reason: '${o.id}: kontras teks primary');
      }
    }
    // Aksen bawaan tidak mengubah palet sama sekali.
    expect(AppPalette.light.withAccent(AppColors.hero), same(AppPalette.light));
    expect(AppPalette.dark.withAccent(AppColors.hero), same(AppPalette.dark));
  });
}
