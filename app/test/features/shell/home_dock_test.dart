import 'dart:io';

import 'package:djournal/core/theme.dart';
import 'package:djournal/core/tokens.dart';
import 'package:djournal/features/shell/presentation/home_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = {
  'id': ['Hari Ini', 'Jurnal', 'Keuangan', 'Laporan'],
  'en': ['Today', 'Journal', 'Money', 'Report'],
  'panjang': ['Hari Ini Juga', 'Buku Harian', 'Keuanganku', 'Laporan Bulan'],
};

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double scale,
  required List<String> labels,
  int index = 0,
}) async {
  tester.view.physicalSize = Size(width, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: HomeDock.sideMargin(width),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: HomeDock(
                index: index,
                onSelect: (_) {},
                onAdd: () {},
                items: [for (final l in labels) (Icons.home_outlined, l)],
                addLabel: 'Tambah',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Poppins');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$w.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await loader.load();
  });

  for (final MapEntry(key: name, value: labels) in _labels.entries) {
    testWidgets('tulisan ($name) selalu di dalam lengkung latar tab', (
      tester,
    ) async {
      for (final width in [300.0, 320.0, 360.0, 393.0, 412.0, 480.0, 673.0]) {
        for (final scale in [0.85, 1.0, 1.3, 2.0]) {
          await _pump(tester, width: width, scale: scale, labels: labels);
          expect(tester.takeException(), isNull, reason: '$width@$scale');
          for (final label in labels) {
            final text = find.text(label);
            final box = tester.getRect(text);
            final pill = tester.getRect(
              find.ancestor(of: text, matching: find.byType(AnimatedContainer)),
            );
            final shape = RRect.fromRectAndRadius(
              pill,
              const Radius.circular(AppRadius.xl),
            );
            // 2 px terbawah kotak teks hanya ruang antarbaris.
            final y = box.bottom - 2;
            for (final p in [Offset(box.left, y), Offset(box.right - 0.1, y)]) {
              expect(
                shape.contains(p),
                isTrue,
                reason: '$label keluar di $width@$scale: $box dari $pill',
              );
            }
          }
        }
      }
    });
  }

  testWidgets('tombol tambah tetap di tengah dan ukuran tulisan seragam', (
    tester,
  ) async {
    for (final width in [320.0, 360.0, 412.0]) {
      await _pump(tester, width: width, scale: 1.0, labels: _labels['id']!);
      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        closeTo(width / 2, 0.5),
      );
      final sizes = {
        for (final l in _labels['id']!)
          tester.widget<Text>(find.text(l)).style!.fontSize!,
      };
      expect(sizes, hasLength(1));
      // Tidak terlalu kecil untuk dibaca.
      expect(sizes.single, greaterThanOrEqualTo(width < 360 ? 8.5 : 10));
    }
  });

  testWidgets('tiap tab cukup lebar untuk disentuh', (tester) async {
    await _pump(tester, width: 320, scale: 1.0, labels: _labels['id']!);
    for (final l in _labels['id']!) {
      final pill = tester.getSize(
        find.ancestor(
          of: find.text(l),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(pill.width, greaterThanOrEqualTo(40), reason: l);
      expect(pill.height, greaterThanOrEqualTo(48), reason: l);
    }
  });
}
