import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../ui/common.dart';

/// Warna latar splash, sama dengan latar icon dan splash bawaan Android
/// (lihat flutter_native_splash di pubspec.yaml).
const splashColor = Color(0xFFCDEBDD);

/// Sisi kanvas kucing (dp). Sama dengan ukuran icon splash Android 12 dan
/// tool/icon/out/splash.png, jadi frame pertama menyambung tanpa lompatan.
const _catSize = 288.0;

const _duration = Duration(milliseconds: 1600);

/// true setelah animasi pembuka selesai. Layar PIN menunggu ini sebelum
/// menawarkan biometrik, supaya dialognya tidak muncul di atas splash.
final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

class SplashDone extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() => state = true;
}

/// Animasi pembuka (desain "Splash B — kucing melompat" di canvas):
/// melanjutkan splash bawaan Android, kucing melompat, telinga bergoyang,
/// mata berkedip, lalu memudar ke app. Hanya sekali saat app dibuka.
class SplashOverlay extends ConsumerStatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends ConsumerState<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: _duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  bool _done = false;

  // Lompatan: jongkok, naik, mendarat, memantul kecil.
  late final _jumpY = _keys(250, 850, [0, 0, -12, 0, 0, 0], _jumpWeights);
  late final _jumpSx = _keys(250, 850, [
    1,
    1.08,
    .95,
    1.06,
    .98,
    1,
  ], _jumpWeights);
  late final _jumpSy = _keys(250, 850, [
    1,
    .9,
    1.06,
    .94,
    1.02,
    1,
  ], _jumpWeights);
  late final _ear = _keys(750, 1050, [0, -12, 4, 0], [40, 30, 30]);
  late final _blink = _keys(950, 1130, [1, .1, 1], [50, 50]);
  late final _sparkScale = _keys(
    600,
    900,
    [.2, 1.15, 1],
    [60, 40],
    Curves.easeOut,
  );
  late final _sparkOpacity = _keys(
    600,
    900,
    [0, 1, 1],
    [60, 40],
    Curves.easeOut,
  );
  late final _wordOpacity = _keys(700, 1050, [0, 1], [1], Curves.easeOut);
  late final _wordY = _keys(700, 1050, [10, 0], [1], Curves.easeOut);
  late final _exitOpacity = _keys(1280, 1600, [1, 0], [1], Curves.easeIn);
  late final _exitScale = _keys(1280, 1600, [1, 1.12], [1], Curves.easeIn);

  static const _jumpWeights = [15.0, 30.0, 27.0, 14.0, 14.0];

  /// Seperti @keyframes CSS: [values] dilewati berurutan antara [fromMs]
  /// dan [toMs], tiap segmen memakai [curve].
  Animation<double> _keys(
    int fromMs,
    int toMs,
    List<double> values,
    List<double> weights, [
    Curve curve = Curves.easeInOut,
  ]) {
    final total = _duration.inMilliseconds;
    return TweenSequence([
      for (var i = 0; i < weights.length; i++)
        TweenSequenceItem(
          tween: Tween(
            begin: values[i],
            end: values[i + 1],
          ).chain(CurveTween(curve: curve)),
          weight: weights[i],
        ),
    ]).animate(
      CurvedAnimation(
        parent: _c,
        curve: Interval(fromMs / total, toMs / total),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _c.isAnimating) return;
    // Pengaturan "hapus animasi" di HP: langsung masuk app.
    if (MediaQuery.disableAnimationsOf(context)) {
      _finish();
    } else {
      _c.forward();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    // Bisa terpanggil saat build pertama; ubah provider setelah frame ini.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(splashDoneProvider.notifier).finish();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
            // Jangan sampai tap tembus ke layar PIN yang belum terlihat.
            child: AbsorbPointer(
              child: Semantics(
                label: context.l10n.appName,
                child: AnimatedBuilder(animation: _c, builder: _frame),
              ),
            ),
          ),
      ],
    );
  }

  Widget _frame(BuildContext context, Widget? _) {
    final font = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Opacity(
      opacity: _exitOpacity.value,
      // Material, bukan ColoredBox: overlay ada di atas Navigator, jadi
      // tanpa ini teks tidak punya gaya dasar (garis bawah kuning).
      child: Material(
        color: splashColor,
        child: Transform.scale(
          scale: _exitScale.value,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size.square(_catSize),
                    painter: _CatPainter(
                      jumpY: _jumpY.value,
                      scaleX: _jumpSx.value,
                      scaleY: _jumpSy.value,
                      earDegrees: _ear.value,
                      blink: _blink.value,
                      sparkScale: _sparkScale.value,
                      sparkOpacity: _sparkOpacity.value,
                    ),
                  ),
                ),
                // Tepat di bawah badan kucing (y 82 dari 108 di kanvas).
                Positioned(
                  left: 0,
                  right: 0,
                  top: box.maxHeight / 2 + 90,
                  child: Opacity(
                    opacity: _wordOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _wordY.value),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.appName,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            context.l10n.splashTagline,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2F5A4C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kucing dari tool/icon/icon_foreground.svg (viewBox 108), digambar ulang
/// per bagian supaya telinga, mata, dan badan bisa digerakkan sendiri.
/// CustomPainter dipakai, bukan SVG, karena SVG dimuat asinkron dan frame
/// pertama splash harus langsung lengkap.
class _CatPainter extends CustomPainter {
  _CatPainter({
    required this.jumpY,
    required this.scaleX,
    required this.scaleY,
    required this.earDegrees,
    required this.blink,
    required this.sparkScale,
    required this.sparkOpacity,
  });

  final double jumpY;
  final double scaleX;
  final double scaleY;
  final double earDegrees;
  final double blink;
  final double sparkScale;
  final double sparkOpacity;

  static const _ink = Color(0xFF4A5A54);
  static const _paper = Color(0xFFFFF9F0);

  static Paint _fill(Color c) => Paint()..color = c;

  static Paint _stroke(double width, [Color c = _ink]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108);

    canvas.save();
    // Lompatan berporos di kaki (tengah bawah badan).
    canvas
      ..translate(54, 82 + jumpY)
      ..scale(scaleX, scaleY)
      ..translate(-54, -82);

    final rad = earDegrees * 3.141592653589793 / 180;
    _ear(
      canvas,
      pivot: const Offset(47, 52),
      angle: rad,
      outer: Path()
        ..moveTo(35.5, 52)
        ..lineTo(39, 29.5)
        ..quadraticBezierTo(40.5, 26.5, 43.5, 28.8)
        ..lineTo(52, 40)
        ..close(),
      inner: Path()
        ..moveTo(40, 40)
        ..lineTo(41.3, 33.5)
        ..lineTo(46.5, 39)
        ..close(),
    );
    _ear(
      canvas,
      pivot: const Offset(61, 52),
      angle: -rad,
      outer: Path()
        ..moveTo(72.5, 52)
        ..lineTo(69, 29.5)
        ..quadraticBezierTo(67.5, 26.5, 64.5, 28.8)
        ..lineTo(56, 40)
        ..close(),
      inner: Path()
        ..moveTo(68, 40)
        ..lineTo(66.7, 33.5)
        ..lineTo(61.5, 39)
        ..close(),
    );

    final body = RRect.fromLTRBR(34, 39, 74, 82, const Radius.circular(10));
    canvas
      ..drawRRect(body, _fill(_paper))
      ..drawRRect(body, _stroke(2.2));

    for (final x in const [46.0, 62.0]) {
      canvas
        ..save()
        ..translate(x, 54)
        ..scale(1, blink)
        ..translate(-x, -54)
        ..drawOval(
          Rect.fromCenter(center: Offset(x, 54), width: 6.6, height: 7.8),
          _fill(const Color(0xFF3D4B46)),
        )
        ..drawCircle(Offset(x + 1.3, 52.5), 1.3, _fill(Colors.white))
        ..restore();
    }

    final cheek = _fill(const Color(0xFFF7B5B9));
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(41, 59.5),
          width: 5.6,
          height: 3.4,
        ),
        cheek,
      )
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(67, 59.5),
          width: 5.6,
          height: 3.4,
        ),
        cheek,
      )
      ..drawPath(
        Path()
          ..moveTo(52.6, 57.6)
          ..quadraticBezierTo(54, 56.6, 55.4, 57.6)
          ..lineTo(54, 59.1)
          ..close(),
        _fill(const Color(0xFFF29CA3)),
      )
      ..drawPath(
        Path()
          ..moveTo(51.2, 60)
          ..quadraticBezierTo(52.6, 62, 54, 60)
          ..quadraticBezierTo(55.4, 62, 56.8, 60),
        _stroke(1.1),
      )
      ..drawLine(
        const Offset(41, 67.5),
        const Offset(67, 67.5),
        _stroke(2.6, const Color(0xFF8EC5AB)),
      )
      ..drawLine(
        const Offset(41, 72.5),
        const Offset(67, 72.5),
        _stroke(2.6, const Color(0xFF8EC5AB)),
      )
      ..drawLine(
        const Offset(41, 77.5),
        const Offset(56, 77.5),
        _stroke(2.6, const Color(0xFFF5BE86)),
      )
      ..restore();

    if (sparkOpacity > 0) {
      _spark(canvas, const Offset(27, 38), 4, AppColors.primary);
      _spark(canvas, const Offset(83, 31), 3, const Color(0xFFE59A5C));
    }
  }

  void _ear(
    Canvas canvas, {
    required Offset pivot,
    required double angle,
    required Path outer,
    required Path inner,
  }) {
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(angle)
      ..translate(-pivot.dx, -pivot.dy)
      ..drawPath(outer, _fill(_paper))
      ..drawPath(outer, _stroke(2.2))
      ..drawPath(inner, _fill(const Color(0xFFF8C8CC)))
      ..restore();
  }

  /// Bintang empat sudut berlengkung, [r] = jarak ujung dari pusat.
  void _spark(Canvas canvas, Offset c, double r, Color color) {
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..scale(sparkScale)
      ..drawPath(
        Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..quadraticBezierTo(0, 0, 0, r)
          ..quadraticBezierTo(0, 0, -r, 0)
          ..quadraticBezierTo(0, 0, 0, -r)
          ..close(),
        _fill(color.withValues(alpha: sparkOpacity)),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_CatPainter old) =>
      old.jumpY != jumpY ||
      old.scaleX != scaleX ||
      old.scaleY != scaleY ||
      old.earDegrees != earDegrees ||
      old.blink != blink ||
      old.sparkScale != sparkScale ||
      old.sparkOpacity != sparkOpacity;
}
