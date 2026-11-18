import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/common.dart';

/// Pengaturan â€º Tampilan â€º Kustom: pilih warna aksen sendiri lewat geser
/// warna/kepekatan/kecerahan atau kode hex, dengan pratinjau langsung.
/// Mengembalikan '#RRGGBB' saat "Pakai warna", null saat batal.
class CustomAccentSheet extends StatefulWidget {
  const CustomAccentSheet({
    super.key,
    required this.initial,
    this.recent = const [],
    this.title,
    this.accentPreview = true,
  });

  final Color initial;

  /// Warna kustom yang pernah dipakai ('#RRGGBB').
  final List<String> recent;

  /// Judul lain (mis. warna roda); null = judul aksen.
  final String? title;

  /// Tampilkan pratinjau & catatan khusus warna aksen.
  final bool accentPreview;

  static Future<String?> open(
    BuildContext context, {
    required Color initial,
    List<String> recent = const [],
    String? title,
    bool accentPreview = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CustomAccentSheet(
        initial: initial,
        recent: recent,
        title: title,
        accentPreview: accentPreview,
      ),
    );
  }

  @override
  State<CustomAccentSheet> createState() => _CustomAccentSheetState();
}

/// Batas kecerahan di penggeser: di luar ini warna jadi hampir putih/hitam.
const _minLightness = 0.12;
const _maxLightness = 0.88;

class _CustomAccentSheetState extends State<CustomAccentSheet> {
  final _hex = TextEditingController();
  late HSLColor _hsl;

  /// Hex yang diketik dan valid; dipakai apa adanya supaya tidak bergeser
  /// karena pembulatan HSL. Null setelah penggeser digerakkan.
  String? _typedHex;
  bool _hexInvalid = false;

  Color get _draft => _typedHex != null ? hexColor(_typedHex!) : _hsl.toColor();

  @override
  void initState() {
    super.initState();
    _setFromHex(colorHex(widget.initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setFromHex(String hex) {
    final h = AccentPresets.normalizeHex(hex);
    final hsl = HSLColor.fromColor(hexColor(h));
    _hsl = hsl.withLightness(
      hsl.lightness.clamp(_minLightness, _maxLightness).toDouble(),
    );
    _typedHex = h;
    _hexInvalid = false;
    _hex.text = h;
  }

  void _slide(HSLColor hsl) {
    setState(() {
      _hsl = hsl;
      _typedHex = null;
      _hexInvalid = false;
      _hex.text = colorHex(hsl.toColor());
    });
  }

  void _typed(String v) {
    setState(() {
      if (AccentPresets.isHex(v)) {
        final hsl = HSLColor.fromColor(hexColor(AccentPresets.normalizeHex(v)));
        _hsl = hsl.withLightness(
          hsl.lightness.clamp(_minLightness, _maxLightness).toDouble(),
        );
        _typedHex = AccentPresets.normalizeHex(v);
        _hexInvalid = false;
      } else {
        // Baru dianggap salah setelah 6 digit; saat masih mengetik diam saja.
        _hexInvalid = v.replaceFirst('#', '').trim().length >= 6;
      }
    });
  }

  bool get _canApply => AccentPresets.isHex(_hex.text);

  String? _note(BuildContext context) {
    final l = context.l10n;
    final hsl = HSLColor.fromColor(_draft);
    if (hsl.saturation < 0.12) return l.accentNoteGrey;
    // Sama dengan batas di AppPalette.withAccent untuk mode terang.
    if (hsl.lightness > 0.52) return l.accentNoteLight;
    if (hsl.lightness < 0.22) return l.accentNoteDark;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final draft = _draft;
    final hex = colorHex(draft);
    final pv = (c.isDark ? AppPalette.dark : AppPalette.light).withAccent(
      draft,
    );
    final note = widget.accentPreview ? _note(context) : null;
    final h = _hsl.hue, s = _hsl.saturation, li = _hsl.lightness;
    final hueSat = s < 0.45 ? 0.45 : s;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title ?? l.accentCustomTitle,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                l.accentCustomSub,
                style: t.bodySmall?.copyWith(color: c.muted),
              ),
              const SizedBox(height: 14),
              if (widget.accentPreview) ...[
                _Preview(palette: pv),
                const SizedBox(height: 10),
              ],
              _ColorSlider(
                label: l.accentHue,
                valueLabel: '${h.round()}°',
                value: h,
                min: 0,
                max: 360,
                thumb: draft,
                colors: [
                  for (var x = 0; x <= 360; x += 60)
                    HSLColor.fromAHSL(1, x % 360, hueSat, 0.5).toColor(),
                ],
                onChanged: (v) => _slide(_hsl.withHue(v % 360)),
              ),
              _ColorSlider(
                label: l.accentSaturation,
                valueLabel: '${(s * 100).round()}%',
                value: s,
                min: 0,
                max: 1,
                thumb: draft,
                colors: [
                  HSLColor.fromAHSL(1, h, 0, li).toColor(),
                  HSLColor.fromAHSL(1, h, 1, li).toColor(),
                ],
                onChanged: (v) => _slide(_hsl.withSaturation(v)),
              ),
              _ColorSlider(
                label: l.accentLightness,
                valueLabel: '${(li * 100).round()}%',
                value: li,
                min: _minLightness,
                max: _maxLightness,
                thumb: draft,
                colors: [
                  HSLColor.fromAHSL(1, h, s, _minLightness).toColor(),
                  HSLColor.fromAHSL(1, h, s, 0.5).toColor(),
                  HSLColor.fromAHSL(1, h, s, _maxLightness).toColor(),
                ],
                onChanged: (v) => _slide(_hsl.withLightness(v)),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: draft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.line),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hex,
                      onChanged: _typed,
                      maxLength: 7,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        labelText: l.accentHexLabel,
                        counterText: '',
                        errorText: _hexInvalid ? l.accentHexError : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.recent.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  l.accentRecent,
                  style: t.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final r in widget.recent)
                      _RecentSwatch(
                        hex: r,
                        selected: r == hex,
                        onTap: () => setState(() => _setFromHex(r)),
                      ),
                  ],
                ),
              ],
              if (note != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.warnSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: c.onWarnSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: t.bodySmall?.copyWith(color: c.onWarnSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canApply
                          ? () => Navigator.of(context).pop(hex)
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l.accentApply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contoh kecil hasil warna: kartu Total saldo, tombol, dan chip terpilih,
/// memakai palet yang sama dengan yang akan dipakai app.
class _Preview extends StatelessWidget {
  const _Preview({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = palette;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: p.hero,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.totalBalance,
                  style: TextStyle(fontSize: 12, color: p.onHeroMuted),
                ),
                Text(
                  rupiah(2450000),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.onHero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.save,
                  style: TextStyle(
                    color: p.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: p.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.accentPreviewChip,
                  style: TextStyle(
                    color: p.onPrimarySoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.thumb,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color thumb;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.muted;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: style)),
              Text(valueLabel, style: style),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 22,
            trackShape: _GradientTrackShape(colors),
            thumbShape: const _RingThumbShape(),
            thumbColor: thumb,
            overlayColor: thumb.withValues(alpha: 0.16),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            label: label,
            semanticFormatterCallback: (_) => valueLabel,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Track penggeser berupa gradasi warna (bukan bagian aktif/nonaktif).
class _GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _GradientTrackShape(this.colors);

  final List<Color> colors;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    context.canvas
      ..drawRRect(
        rrect,
        Paint()..shader = LinearGradient(colors: colors).createShader(rect),
      )
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x14000000),
      );
  }
}

/// Jempol bulat berwarna [SliderThemeData.thumbColor] dengan cincin putih.
class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape();

  static const _radius = 14.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center.translate(0, 1),
      _radius,
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(center, _radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      _radius - 3,
      Paint()..color = sliderTheme.thumbColor ?? Colors.black,
    );
  }
}

class _RecentSwatch extends StatelessWidget {
  const _RecentSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: hex,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.ink : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hexColor(hex),
                  border: Border.all(color: c.line),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
