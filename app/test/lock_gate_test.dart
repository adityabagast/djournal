import 'package:djournal/data/security/lock_controller.dart';
import 'package:djournal/features/lock/lock_gate.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Status kunci yang diatur langsung oleh test, tanpa secure storage.
class _FakeLock extends LockController {
  @override
  LockState build() =>
      const LockState(loading: false, pinEnabled: true, locked: true);

  void unlock() => state = state.copyWith(locked: false);
}

void main() {
  testWidgets('layar kunci tidak membuat navigasi app macet', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final container = ProviderContainer(
      overrides: [lockProvider.overrideWith(_FakeLock.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => LockGate(child: child!),
          home: const Text('beranda'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Dulu: "A HeroController can not be shared by multiple Navigators".
    expect(tester.takeException(), isNull);

    (container.read(lockProvider.notifier) as _FakeLock).unlock();
    await tester.pumpAndSettle();
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('pengaturan')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('pengaturan'), findsOneWidget);
  });
}
