import 'package:djournal/ui/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('semua pose maskot punya file SVG yang bisa dirender', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [for (final pose in MascotPose.values) Mascot(pose)],
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsNWidgets(MascotPose.values.length));
    for (final pose in MascotPose.values) {
      final data = await rootBundle.loadString(
        'assets/mascot/${pose.name}.svg',
      );
      expect(data, startsWith('<svg'), reason: pose.name);
    }
  });
}
