import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import 'database_providers.dart';

/// Bahasa aplikasi: 'id' (default) atau 'en'.
final localeProvider = StreamProvider<Locale>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch('language')
      .map((code) => Locale(code ?? 'id')),
);

/// Tema pilihan di Pengaturan › Tampilan: 'system' (bawaan), 'light', 'dark'.
final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch('theme_mode')
      .map(
        (v) => switch (v) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
      ),
);

/// Warna aksen pilihan di Pengaturan › Tampilan: id di [AccentPresets]
/// ('sage' bawaan, atau '#RRGGBB' untuk warna kustom).
final accentIdProvider = StreamProvider<String>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch('accent_color')
      .map((v) => v ?? AccentPresets.sage.id),
);

/// Mode privasi: sembunyikan semua nominal uang di aplikasi (true = 'Rp •••••').
final hideAmountsProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch('hide_amounts')
      .map((v) => v == 'true'),
);

