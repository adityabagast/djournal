// Bukan test sungguhan: alat untuk merender SVG icon (tool/icon/) jadi PNG
// 1024×1024 yang dibaca flutter_launcher_icons. Jalankan dari folder app/:
//   flutter test tool/render_icons_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024;

const _jobs = {
  'tool/icon/icon.svg': 'tool/icon/out/icon.png',
  'tool/icon/icon_foreground.svg': 'tool/icon/out/icon_foreground.png',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final job in _jobs.entries) {
    test('render ${job.key}', () async {
      final svg = File(job.key).readAsStringSync();
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      // Ukuran gambar mengikuti viewBox, jadi diperbesar manual ke 1024.
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
        ..scale(_size / info.size.width, _size / info.size.height)
        ..drawPicture(info.picture);
      final image = await recorder.endRecording().toImage(_size, _size);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(job.value)
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
      expect(image.width, _size);
    });
  }
}
