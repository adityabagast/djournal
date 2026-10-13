// Bukan test sungguhan: alat untuk merender pratinjau warna aksen
// (Pengaturan › Tampilan › Warna aksen) ke docs/screenshots/accent-preview.png.
// Jalankan dari folder app/:
//   flutter test tool/accent_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:djournal/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _outFile = '../docs/screenshots/accent-preview.png';
const _size = Size(1140, 1280);
const _pixelRatio = 1.5;

const _names = {
  'sage': 'Hijau sage',
  'ocean': 'Biru laut',
  'violet': 'Ungu',
  'rose': 'Mawar',
  'pink': 'Pink',
  'amber': 'Amber',
  'teal': 'Teal',
};

TextStyle _text(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF1B1F1D),
}) => TextStyle(
  fontFamily: 'Poppins',
  fontSize: size,
  fontWeight: weight,
  color: color,
);

/// Ketebalan tiap file dibaca dari isi font-nya sendiri.
Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// Satu "layar mini": kartu Total saldo, tombol, chip kategori, dan bar
/// progres, semuanya memakai warna turunan dari aksen [p].
Widget _cell(AppPalette p) => Container(
  width: 465,
  height: 150,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: p.background,
    border: Border.all(color: p.line),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.hero,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total saldo', style: _text(11, color: p.onHeroMuted)),
                  const SizedBox(height: 2),
                  Text(
                    'Rp 1.250.000',
                    style: _text(18, weight: FontWeight.w700, color: p.onHero),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Simpan',
                  style: _text(12, weight: FontWeight.w600, color: p.onPrimary),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Makan · Rp 25.000',
                  style: _text(
                    11,
                    weight: FontWeight.w500,
                    color: p.onPrimarySoft,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        height: 8,
        decoration: BoxDecoration(
          color: p.track,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          widthFactor: 0.62,
          child: Container(
            decoration: BoxDecoration(
              color: p.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ],
  ),
);

/// Satu baris aksen: nama, contoh mode terang, contoh mode gelap.
Widget _row(AccentOption o) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SizedBox(
      width: 120,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: o.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _names[o.id] ?? o.id,
            style: _text(13, weight: FontWeight.w600),
          ),
        ],
      ),
    ),
    _cell(AppPalette.light.withAccent(o.color)),
    const SizedBox(width: 16),
    _cell(AppPalette.dark.withAccent(o.color)),
  ],
);

Widget _sheet() => Container(
  width: _size.width,
  height: _size.height,
  color: const Color(0xFFFFFFFF),
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Nyawtat · warna aksen', style: _text(22, weight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(
        'Pengaturan › Tampilan › Warna aksen — kiri mode terang, kanan mode gelap.',
        style: _text(13, color: const Color(0xFF5C625F)),
      ),
      const SizedBox(height: 16),
      for (final o in AccentPresets.all) ...[_row(o), const SizedBox(height: 14)],
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final shotKey = GlobalKey();

  setUpAll(() async {
    // Di flutter test font default berupa kotak-kotak; muat font asli.
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Poppins-$w.ttf',
    ]);
  });

  testWidgets('render pratinjau warna aksen', (tester) async {
    tester.view.physicalSize = _size * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(key: shotKey, child: _sheet()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(_outFile)
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
    expect(File(_outFile).existsSync(), isTrue);
  });
}
