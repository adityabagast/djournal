// Bukan test sungguhan: alat untuk merender maskot SVG (assets/mascot/) jadi
// PNG untuk widget layar utama Android, yang tidak bisa memakai SVG.
// Jalankan dari folder app/:
//   flutter test tool/render_widget_mascots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lebar PNG; tinggi mengikuti viewBox.
const _width = 192;
const _outDir = 'android/app/src/main/res/drawable-nodpi';
const _poses = ['koin', 'sedih', 'menulis', 'senang'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final pose in _poses) {
    test('render $pose', () async {
      final svg = File('assets/mascot/$pose.svg').readAsStringSync();
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      final scale = _width / info.size.width;
      final height = (info.size.height * scale).round();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
        ..scale(scale)
        ..drawPicture(info.picture);
      final image = await recorder.endRecording().toImage(_width, height);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/widget_kucing_$pose.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
      expect(image.width, _width);
    });
  }
}
