import 'package:djournal/features/settings/presentation/about_section.dart';
import 'package:djournal/features/update/domain/changelog.dart';
import 'package:djournal/features/update/domain/release_info.dart';
import 'package:djournal/features/update/presentation/version_history_screen.dart';
import 'package:djournal/features/update/providers/changelog_provider.dart';
import 'package:djournal/features/update/providers/update_controller.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Fake extends UpdateController {
  _Fake(this._s);

  final UpdateState _s;

  @override
  UpdateState build() => _s;
}

const _sample = '''
## 0.2.0 — 2026-11-10

**Baru**
- **Kalender** bulanan

## 0.1.1 — 2026-10-20

**Perbaikan**
- **Streak** aman

## 0.1.0 — 2026-10-09

**Baru**
- **Jurnal** harian
''';

Widget _app(
  Widget home, {
  UpdateState state = const UpdateState(),
  String version = '0.1.1',
}) => ProviderScope(
  overrides: [
    updateProvider.overrideWith(() => _Fake(state)),
    updateAutoProvider.overrideWithValue(const AsyncValue.data(true)),
    updateLastCheckProvider.overrideWithValue(const AsyncValue.data(null)),
    changelogProvider.overrideWith((ref) async => parseChangelog(_sample)),
    appVersionProvider.overrideWithValue(
      AsyncValue.data(
        PackageInfo(
          appName: 'Nyawtat',
          packageName: 'dev.nyawtat.app',
          version: version,
          buildNumber: '2',
        ),
      ),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('id'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  ),
);

void main() {
  testWidgets('dikelompokkan per bulan dan versi terpasang terbuka', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const VersionHistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(find.text('Versi kamu'), findsOneWidget);
    // Hanya isi versi terpasang (0.1.1) yang tampil.
    expect(find.text('Streak aman'), findsOneWidget);
    expect(find.text('Kalender bulanan'), findsNothing);
  });

  testWidgets('ketuk untuk membuka dan menutup', (tester) async {
    await tester.pumpWidget(_app(const VersionHistoryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0.2.0'));
    await tester.pumpAndSettle();
    expect(find.text('Kalender bulanan'), findsOneWidget);
    await tester.tap(find.text('0.1.1'));
    await tester.pumpAndSettle();
    expect(find.text('Streak aman'), findsNothing);
  });

  testWidgets('versi terpasang tidak ada di daftar: yang teratas terbuka', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const VersionHistoryScreen(), version: '9.9.9'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Versi kamu'), findsNothing);
    expect(find.text('Kalender bulanan'), findsOneWidget);
  });

  testWidgets('banner hanya muncul kalau ada versi baru', (tester) async {
    await tester.pumpWidget(_app(const VersionHistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('tersedia'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _app(
        const VersionHistoryScreen(),
        state: const UpdateState(
          phase: UpdatePhase.available,
          release: ReleaseInfo(version: '0.3.0', notes: 'x', pageUrl: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Versi 0.3.0 tersedia'), findsOneWidget);
    await tester.tap(find.text('Lihat'));
    await tester.pumpAndSettle();
    expect(find.text('Apa yang baru di 0.3.0'), findsOneWidget);
  });

  testWidgets('Pengaturan › Tentang › Riwayat versi dibuka di dalam app', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: SingleChildScrollView(child: AboutSection()))),
    );
    await tester.ensureVisible(find.text('Riwayat versi'));
    await tester.tap(find.text('Riwayat versi'));
    await tester.pumpAndSettle();
    expect(find.byType(VersionHistoryScreen), findsOneWidget);
  });
}
