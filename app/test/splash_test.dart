import 'package:djournal/features/splash/splash_overlay.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({bool disableAnimations = false}) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: SplashOverlay(child: child!),
  ),
  home: const Text('beranda'),
);

void main() {
  testWidgets('splash tampil sekali lalu hilang', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _app()),
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('jurnal & catatan uang'), findsOneWidget);
    expect(container.read(splashDoneProvider), isFalse);

    // Tap selama splash tidak tembus ke layar di bawahnya.
    expect(find.byType(AbsorbPointer), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('jurnal & catatan uang'), findsNothing);
    expect(find.text('beranda'), findsOneWidget);
    expect(container.read(splashDoneProvider), isTrue);
  });

  testWidgets('tanpa animasi kalau animasi dimatikan di HP', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(disableAnimations: true),
      ),
    );
    await tester.pump();

    expect(find.text('jurnal & catatan uang'), findsNothing);
    expect(container.read(splashDoneProvider), isTrue);
  });
}
