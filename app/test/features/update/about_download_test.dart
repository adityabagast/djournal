import 'package:djournal/features/feedback/presentation/feedback_screen.dart';
import 'package:djournal/features/update/providers/update_controller.dart';
import 'package:djournal/features/update/domain/release_info.dart';
import 'package:djournal/features/settings/presentation/about_section.dart';
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

Widget _app(UpdateState s) => ProviderScope(
  overrides: [
    updateProvider.overrideWith(() => _Fake(s)),
    updateAutoProvider.overrideWithValue(const AsyncValue.data(true)),
    updateLastCheckProvider.overrideWithValue(const AsyncValue.data(null)),
    appVersionProvider.overrideWithValue(
      AsyncValue.data(
        PackageInfo(
          appName: 'Nyawtat',
          packageName: 'dev.nyawtat.app',
          version: '0.12.0',
          buildNumber: '15',
        ),
      ),
    ),
  ],
  child: const MaterialApp(
    locale: Locale('id'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: SingleChildScrollView(child: AboutSection())),
  ),
);

const _release = ReleaseInfo(
  version: '0.13.0',
  notes: 'x',
  pageUrl: '',
  apkSize: 20 * 1024 * 1024,
);

void main() {
  testWidgets('Pengaturan › Tentang menampilkan progres saat mengunduh', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const UpdateState(
          phase: UpdatePhase.downloading,
          release: _release,
          progress: 0.4,
        ),
      ),
    );
    expect(find.text('Mengunduh 0.13.0…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);
    // Tombol Unduh hilang selama unduhan berjalan.
    expect(find.text('Unduh'), findsNothing);
  });

  testWidgets('Pengaturan › Tentang: siap dipasang punya tombol Pasang', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const UpdateState(
          phase: UpdatePhase.ready,
          release: _release,
          progress: 1,
          apkPath: 'x.apk',
        ),
      ),
    );
    expect(find.text('Pasang sekarang'), findsOneWidget);
  });

  testWidgets('Pengaturan › Tentang › Kirim masukan membuka form', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const UpdateState()));
    await tester.ensureVisible(find.text('Kirim masukan'));
    await tester.tap(find.text('Kirim masukan'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackScreen), findsOneWidget);
  });
}
