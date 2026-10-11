// Bukan test sungguhan: alat untuk merender SVG icon (tool/icon/) jadi PNG
// yang dibaca flutter_launcher_icons dan flutter_native_splash. Jalankan
// dari folder app/:
//   flutter test tool/render_icons_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// (SVG sumber, PNG hasil, ukuran sisi dalam piksel).
const _jobs = [
  ('tool/icon/icon.svg', 'tool/icon/out/icon.png', 1024),
  ('tool/icon/icon_foreground.svg', 'tool/icon/out/icon_foreground.png', 1024),
  // Splash: foreground yang sama di kanvas 1152 px = 288dp di xxxhdpi,
  // ukuran icon splash Android 12 (lingkaran terlihat 192dp). Android lama
  // memakai gambar yang sama supaya ukurannya cocok dengan SplashOverlay.
  ('tool/icon/icon_foreground.svg', 'tool/icon/out/splash.png', 1152),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (source, output, size) in _jobs) {
    test('render $output', () async {
      final svg = File(source).readAsStringSync();
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      // Ukuran gambar mengikuti viewBox, jadi diperbesar manual.
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
        ..scale(size / info.size.width, size / info.size.height)
        ..drawPicture(info.picture);
      final image = await recorder.endRecording().toImage(size, size);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(output)
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
      expect(image.width, size);
    });
  }
}
