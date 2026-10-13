import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/lock/lock_gate.dart';
import 'features/shell/home_shell.dart';
import 'features/splash/splash_overlay.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';

class NyawtatApp extends ConsumerWidget {
  const NyawtatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).value ?? const Locale('id');
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final accent =
        AccentPresets.resolve(ref.watch(accentIdProvider).value);
    ref.listen(themeModeProvider, (_, next) {
      final mode = next.value;
      if (mode != null) _syncNativeNightMode(mode);
    });
    return MaterialApp(
      title: 'Nyawtat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, accent: accent),
      darkTheme: buildTheme(Brightness.dark, accent: accent),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Layar kunci PIN menutupi semua halaman, termasuk dialog; animasi
      // pembuka menutupi layar kunci sampai selesai.
      builder: (context, child) =>
          SplashOverlay(child: LockGate(child: child!)),
      home: const HomeShell(),
    );
  }
}

const _themeChannel = MethodChannel('nyawtat/theme');

/// Memberi tahu Android tema pilihan user, supaya splash bawaan (sebelum
/// Flutter jalan) ikut terang/gelap. Hanya berefek di Android 12+.
Future<void> _syncNativeNightMode(ThemeMode mode) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _themeChannel.invokeMethod<void>('setNightMode', mode.name);
  } on PlatformException catch (e) {
    debugPrint('Gagal mengatur mode malam Android: $e');
  }
}
