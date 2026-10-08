import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/lock/lock_gate.dart';
import 'features/shell/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';

class DJournalApp extends ConsumerWidget {
  const DJournalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).value ?? const Locale('id');
    return MaterialApp(
      title: 'djournal',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Layar kunci PIN menutupi semua halaman, termasuk dialog.
      builder: (context, child) => LockGate(child: child!),
      home: const HomeShell(),
    );
  }
}
