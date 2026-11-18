import 'dart:async';
import 'dart:math' as math;

import 'package:djournal/core/theme.dart';
import 'package:djournal/core/storage/settings_repository.dart';
import 'package:djournal/features/settings/presentation/appearance_section.dart';
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

    AppPalette palette() =>
        Theme.of(tester.element(find.byType(Scaffold)))
            .extension<AppPalette>()!;

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

  testWidgets('warna kustom lewat kode hex disimpan dan dipakai', (
    tester,
  ) async {
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
            home: const Scaffold(
              body: SingleChildScrollView(child: AppearanceSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kustom'));
    await tester.pumpAndSettle();
    expect(find.text('Warna kustom'), findsOneWidget);

    // Hex rusak: tombol Pakai mati dan ada pesan format.
    await tester.enterText(find.byType(TextField), '#12G45Z');
    await tester.pump();
    expect(find.text('Format: #RRGGBB, mis. #1F5F4E'), findsOneWidget);
    final apply = find.widgetWithText(FilledButton, 'Pakai warna');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'c2410c');
    await tester.pump();
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(settings._values['accent_color'], '#C2410C');
    expect(settings._values['accent_recent'], '#C2410C');
    final palette = Theme.of(tester.element(find.byType(AppearanceSection)))
        .extension<AppPalette>()!;
    expect(palette.hero, const Color(0xFFC2410C));
    expect(find.textContaining('Kustom #C2410C'), findsOneWidget);
  });

  test('riwayat warna kustom: rapi, tanpa duplikat, maksimal 6', () {
    expect(AccentPresets.parseRecent(null), isEmpty);
    expect(AccentPresets.parseRecent('#c2410c,rusak,0e7490'), [
      '#C2410C',
      '#0E7490',
    ]);
    var r = <String>[];
    for (final h in [
      '#111111',
      '#222222',
      '#333333',
      '#444444',
      '#555555',
      '#666666',
      '#777777',
    ]) {
      r = AccentPresets.addRecent(r, h);
    }
    expect(r.length, AccentPresets.maxRecent);
    expect(r.first, '#777777');
    r = AccentPresets.addRecent(r, '#444444');
    expect(r.first, '#444444');
    expect(r.where((x) => x == '#444444').length, 1);
    expect(colorHex(const Color(0xFF0E7490)), '#0E7490');
  });

  test('warna kustom apa pun tetap terbaca di mode terang dan gelap', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    for (var h = 0.0; h < 360; h += 30) {
      for (final s in [0.0, 0.5, 1.0]) {
        for (final l in [0.12, 0.5, 0.88]) {
          final seed = HSLColor.fromAHSL(1, h, s, l).toColor();
          for (final base in [AppPalette.light, AppPalette.dark]) {
            final p = base.withAccent(seed);
            final why = '${colorHex(seed)} dark=${base.isDark}';
            expect(ratio(p.primary, p.onPrimary), greaterThan(3), reason: why);
            expect(ratio(p.hero, p.onHero), greaterThan(3), reason: why);
            expect(
              ratio(p.primarySoft, p.onPrimarySoft),
              greaterThan(3),
              reason: why,
            );
          }
        }
      }
    }
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
        final ratio = (math.max(fg, bg) + 0.05) / (math.min(fg, bg) + 0.05);
        expect(ratio, greaterThan(3), reason: '${o.id}: kontras teks primary');
      }
    }
    // Aksen bawaan tidak mengubah palet sama sekali.
    expect(AppPalette.light.withAccent(AppColors.hero), same(AppPalette.light));
    expect(AppPalette.dark.withAccent(AppColors.hero), same(AppPalette.dark));
  });
}
