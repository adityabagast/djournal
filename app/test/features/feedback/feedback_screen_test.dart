import 'package:djournal/core/config.dart';
import 'package:djournal/features/feedback/data/feedback_service.dart';
import 'package:djournal/features/feedback/presentation/feedback_screen.dart';
import 'package:djournal/features/feedback/providers/feedback_providers.dart';
import 'package:djournal/features/update/providers/update_controller.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Fake extends FeedbackService {
  _Fake({this.hasMail = true});

  final bool hasMail;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return hasMail;
  }

  @override
  Future<String?> deviceInfo() async => 'Android 16 · HP Contoh';
}

Future<void> _pump(
  WidgetTester tester,
  _Fake fake, {
  String lang = 'id',
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feedbackServiceProvider.overrideWithValue(fake),
        appVersionProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'Nyawtat',
            packageName: 'dev.nyawtat.app',
            version: '1.2.3',
            buildNumber: '4',
          ),
        ),
      ],
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => FeedbackScreen.open(context),
            child: const Text('buka'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('buka'));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('fbTitle')), 'Grafik hilang');
  await tester.enterText(
    find.byKey(const Key('fbBody')),
    'Buka laporan lalu kosong',
  );
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form kosong ditolak dan email tidak dibuka', (tester) async {
    final fake = _Fake();
    await _pump(tester, fake);
    await _tap(tester, 'Buka aplikasi email');
    expect(find.text('Isi minimal 5 huruf.'), findsOneWidget);
    expect(find.text('Isi minimal 10 huruf.'), findsOneWidget);
    expect(fake.opened, isEmpty);
  });

  testWidgets('lapor bug: email terisi lalu layar konfirmasi', (tester) async {
    final fake = _Fake();
    await _pump(tester, fake);
    await _fill(tester);
    await _tap(tester, 'Keuangan');
    await _tap(tester, 'Parah');
    await _tap(tester, 'Buka aplikasi email');

    final mail = fake.opened.single;
    expect(mail.path, supportEmail);
    expect(
      mail.queryParameters['subject'],
      'Nyawtat · Lapor bug: Grafik hilang',
    );
    final body = mail.queryParameters['body']!;
    expect(body, contains('Bagian: Keuangan'));
    expect(body, contains('Mengganggu: Parah'));
    expect(body, contains('Nyawtat 1.2.3 (4)'));
    expect(body, contains('Android 16 · HP Contoh'));

    expect(find.text('Sudah tekan kirim di email?'), findsOneWidget);
    await _tap(tester, 'Buka email lagi');
    expect(fake.opened, hasLength(2));

    await _tap(tester, 'Ubah tulisan');
    expect(find.text('Grafik hilang'), findsOneWidget);

    await _tap(tester, 'Buka aplikasi email');
    await _tap(tester, 'Sudah dikirim');
    expect(find.byType(FeedbackScreen), findsNothing);
  });

  testWidgets('info perangkat bisa dimatikan', (tester) async {
    final fake = _Fake();
    await _pump(tester, fake);
    await _fill(tester);
    await tester.tap(find.byType(Switch));
    await _tap(tester, 'Buka aplikasi email');
    final body = fake.opened.single.queryParameters['body']!;
    expect(body, isNot(contains('HP Contoh')));
    expect(body, isNot(contains('1.2.3')));
  });

  testWidgets('usul fitur tanpa tingkat gangguan dan info perangkat', (
    tester,
  ) async {
    final fake = _Fake();
    await _pump(tester, fake);
    await _tap(tester, 'Usul fitur');
    expect(find.text('Seberapa mengganggu?'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    await _fill(tester);
    await _tap(tester, 'Buka aplikasi email');
    final mail = fake.opened.single;
    expect(mail.queryParameters['subject'], contains('Usul fitur'));
    expect(mail.queryParameters['body'], isNot(contains('HP Contoh')));
  });

  testWidgets('tanpa aplikasi email: alamat dan teks bisa disalin', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await _pump(tester, _Fake(hasMail: false));
    await _fill(tester);
    await _tap(tester, 'Buka aplikasi email');
    expect(find.text('Aplikasi email tidak ditemukan'), findsOneWidget);
    await _tap(tester, 'Salin alamat');
    await _tap(tester, 'Salin teks');
    expect(copied.first, supportEmail);
    expect(copied.last, contains('Grafik hilang'));
    expect(copied.last, contains('Buka laporan lalu kosong'));
    expect(find.text('Tersalin'), findsOneWidget);

    // Tulisan tetap ada setelah sheet ditutup.
    await _tap(tester, 'Tutup');
    expect(find.text('Grafik hilang'), findsOneWidget);
  });

  testWidgets('pratinjau sama dengan yang dikirim', (tester) async {
    final fake = _Fake();
    await _pump(tester, fake);
    await _fill(tester);
    await _tap(tester, 'Lihat yang akan dikirim');
    expect(find.text(supportEmail), findsOneWidget);
    final shown = tester
        .widget<SelectableText>(find.byKey(const Key('fbPreview')))
        .data!;
    expect(shown, contains('HP Contoh'));
    await _tap(tester, 'Tutup');
    await _tap(tester, 'Buka aplikasi email');
    expect(
      fake.opened.single.queryParameters['body']!.replaceAll('\r\n', '\n'),
      shown,
    );
  });

  testWidgets('kembali: langsung kalau kosong, konfirmasi kalau ada tulisan', (
    tester,
  ) async {
    await _pump(tester, _Fake());
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackScreen), findsNothing);

    await _tap(tester, 'buka');
    await _fill(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Buang masukan ini?'), findsOneWidget);
    await _tap(tester, 'Lanjut menulis');
    expect(find.text('Grafik hilang'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _tap(tester, 'Buang');
    expect(find.byType(FeedbackScreen), findsNothing);
  });

  testWidgets('kembali dari layar konfirmasi tidak membuang tulisan', (
    tester,
  ) async {
    await _pump(tester, _Fake());
    await _fill(tester);
    await _tap(tester, 'Buka aplikasi email');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Grafik hilang'), findsOneWidget);
  });

  testWidgets('pratinjau form kosong memakai penanda', (tester) async {
    await _pump(tester, _Fake());
    await _tap(tester, 'Lihat yang akan dikirim');
    expect(find.text('Yang akan dikirim'), findsOneWidget);
    expect(
      find.text('Nyawtat · Lapor bug: (judul belum diisi)'),
      findsOneWidget,
    );
    expect(find.textContaining('(cerita belum diisi)'), findsOneWidget);
  });

  testWidgets('teks Inggris tampil', (tester) async {
    await _pump(tester, _Fake(), lang: 'en');
    expect(find.text('Report a bug'), findsOneWidget);
    expect(find.text('Open email app'), findsOneWidget);
  });
}
