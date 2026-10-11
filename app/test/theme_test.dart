import 'dart:math';

import 'package:djournal/core/theme.dart';
import 'package:djournal/features/money/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('buildTheme memasang palet sesuai kecerahan', () {
    final dark = buildTheme(Brightness.dark);
    final light = buildTheme(Brightness.light);
    expect(dark.extension<AppPalette>(), same(AppPalette.dark));
    expect(light.extension<AppPalette>(), same(AppPalette.light));
    expect(dark.scaffoldBackgroundColor, AppPalette.dark.background);
    expect(dark.colorScheme.brightness, Brightness.dark);
  });

  for (final p in [AppPalette.light, AppPalette.dark]) {
    final name = p.isDark ? 'gelap' : 'terang';

    test('teks terbaca di kartu dan halaman ($name)', () {
      for (final bg in [p.surface, p.background]) {
        expect(_contrast(p.ink, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.muted, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.expense, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.income, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.primary, bg), greaterThanOrEqualTo(4.5));
      }
      expect(_contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(p.onPrimarySoft, p.primarySoft),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(p.warning, p.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(p.onWarnSoft, p.warnSoft), greaterThanOrEqualTo(4.5));
    });
  }

  test('warna kategori terbaca di chip-nya (gelap)', () {
    // Mode terang memakai warna desain awal apa adanya; beberapa (jingga,
    // zaitun) masih di bawah 4,5:1 dan dibiarkan supaya kategori lama tidak
    // berubah warna.
    const p = AppPalette.dark;
    for (final hex in categoryPalette) {
      final raw = hexColor(hex);
      expect(
        _contrast(p.fg(raw), p.soft(raw)),
        greaterThanOrEqualTo(4.5),
        reason: hex,
      );
    }
  });

  test('mode terang tidak mengubah warna kategori', () {
    const c = Color(0xFF9A3412);
    expect(AppPalette.light.fg(c), c);
    expect(
      AppPalette.light.tint(const Color(0xFFE3F3EA)),
      const Color(0xFFE3F3EA),
    );
    expect(
      AppPalette.dark.fg(c).computeLuminance(),
      greaterThan(c.computeLuminance()),
    );
  });
}
