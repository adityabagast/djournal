import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../domain/games.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../money/presentation/tx_form_screen.dart';
import '../../settings/presentation/custom_accent_sheet.dart';

/// Kunci app_settings (lokal, tidak disinkronkan) untuk isi roda yang diubah
/// user: JSON {presetId: [pilihan]}.
const _wheelListsKey = 'game_wheel_lists';

final wheelListsProvider = StreamProvider<Map<String, List<String>>>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(_wheelListsKey).map((v) {
    if (v == null) return const {};
    final m = jsonDecode(v) as Map<String, dynamic>;
    return m.map((k, x) => MapEntry(k, (x as List).cast<String>()));
  }),
);

/// Kunci app_settings (lokal) untuk palet & warna kustom roda.
const _wheelColorsKey = 'game_wheel_colors';

final wheelColorsProvider = StreamProvider<WheelColors>(
  (ref) =>
      ref.watch(settingsRepositoryProvider).watch(_wheelColorsKey).map((v) {
        if (v == null) return const WheelColors();
        try {
          final j = jsonDecode(v);
          return j is Map<String, dynamic>
              ? WheelColors.fromJson(j)
              : const WheelColors();
        } on FormatException {
          return const WheelColors();
        }
      }),
);

const _rainbow = [
  Color(0xFF1F5F4E),
  Color(0xFFC2410C),
  Color(0xFF1D4E89),
  Color(0xFF9A5B12),
  Color(0xFF7E3AA8),
  Color(0xFFBE185D),
];

/// Palet bertint: (kepekatan, warna dasar).
const _tints = <String, (double, List<Color>)>{
  'pastel': (
    0.30,
    [
      Color(0xFFF472B6),
      Color(0xFFFB923C),
      Color(0xFFFACC15),
      Color(0xFF34D399),
      Color(0xFF38BDF8),
      Color(0xFFA78BFA),
    ],
  ),
  'sunset': (
    0.22,
    [
      Color(0xFFDC2626),
      Color(0xFFEA580C),
      Color(0xFFD97706),
      Color(0xFFDB2777),
      Color(0xFF9333EA),
      Color(0xFFE11D48),
    ],
  ),
  'ocean': (
    0.22,
    [
      Color(0xFF0E7490),
      Color(0xFF1D4ED8),
      Color(0xFF0891B2),
      Color(0xFF4338CA),
      Color(0xFF0F766E),
      Color(0xFF2563EB),
    ],
  ),
  'forest': (
    0.22,
    [
      Color(0xFF15803D),
      Color(0xFF65A30D),
      Color(0xFF92400E),
      Color(0xFF047857),
      Color(0xFF4D7C0F),
      Color(0xFFA16207),
    ],
  ),
};

/// Contoh warna cepat untuk slot kustom.
const _swatches = [
  '#F6B8B8',
  '#F7D58B',
  '#B9E3A3',
  '#9AD8C0',
  '#A9C8F0',
  '#CDB4EE',
  '#F4A6C8',
  '#C2410C',
  '#1F5F4E',
  '#1D4E89',
  '#7E3AA8',
  '#3F3F46',
];

/// Tulisan hitam/putih yang terbaca di atas [bg].
Color _labelOn(Color bg) =>
    bg.computeLuminance() > 0.18 ? const Color(0xFF1A1F1D) : Colors.white;

/// Warna irisan + warna tulisannya untuk [palette].
List<(Color, Color)> _slices(AppPalette c, WheelColors w, [String? palette]) {
  Color mix(Color base, double t) => Color.lerp(c.surface, base, t)!;
  final p = palette ?? w.palette;
  final tint = _tints[p];
  return switch (p) {
    'custom' => [
      for (final h in w.custom) (hexColor(h), _labelOn(hexColor(h))),
    ],
    'accent' => [
      for (final t in const [.12, .26, .18, .32, .15, .22])
        (mix(c.primary, t), c.ink),
    ],
    _ when tint != null => [for (final b in tint.$2) (mix(b, tint.$1), c.ink)],
    _ => [for (final b in _rainbow) (c.soft(b), c.ink)],
  };
}

String _paletteName(AppLocalizations l, String p) => switch (p) {
  'accent' => l.gameWheelPaletteAccent,
  'pastel' => l.gameWheelPalettePastel,
  'sunset' => l.gameWheelPaletteSunset,
  'ocean' => l.gameWheelPaletteOcean,
  'forest' => l.gameWheelPaletteForest,
  'custom' => l.gameWheelPaletteCustom,
  _ => l.gameWheelPaletteRainbow,
};

enum _Preset { food, drink, yesNo, activity }

extension on _Preset {
  String label(AppLocalizations l) => switch (this) {
    _Preset.food => l.gameWheelFood,
    _Preset.drink => l.gameWheelDrink,
    _Preset.yesNo => l.gameWheelYesNo,
    _Preset.activity => l.gameWheelActivity,
  };

  List<String> defaults(AppLocalizations l) => switch (this) {
    _Preset.food => l.gameWheelFoodDefaults,
    _Preset.drink => l.gameWheelDrinkDefaults,
    _Preset.yesNo => l.gameWheelYesNoDefaults,
    _Preset.activity => l.gameWheelActivityDefaults,
  }.split('|');

  /// Hasilnya biasanya jadi pengeluaran, jadi tampilkan tombol catat.
  bool get isSpending => this == _Preset.food || this == _Preset.drink;
}

/// Roda putar dan batu gunting kertas dalam dua tab; [initialTab] 0 = roda,
/// 1 = suit.
class WheelRpsScreen extends StatefulWidget {
  const WheelRpsScreen({super.key, this.initialTab = 0, this.random});

  final int initialTab;

  /// Bisa diisi di tes supaya hasilnya pasti.
  final math.Random? random;

  static Future<void> open(BuildContext context, {int initialTab = 0}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WheelRpsScreen(initialTab: initialTab),
        ),
      );

  @override
  State<WheelRpsScreen> createState() => _WheelRpsScreenState();
}

class _WheelRpsScreenState extends State<WheelRpsScreen> {
  late int _tab = widget.initialTab;
  late final math.Random _random = widget.random ?? math.Random();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.games,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            l.gamesSub,
            style: TextStyle(color: context.colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text(l.gameWheel)),
              ButtonSegment(value: 1, label: Text(l.gameRps)),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 18),
          // Offstage menjaga skor & isi roda saat pindah tab.
          Offstage(
            offstage: _tab != 0,
            child: _WheelGame(random: _random),
          ),
          Offstage(
            offstage: _tab != 1,
            child: _RpsGame(random: _random),
          ),
        ],
      ),
    );
  }
}

class _WheelGame extends ConsumerStatefulWidget {
  const _WheelGame({required this.random});

  final math.Random random;

  @override
  ConsumerState<_WheelGame> createState() => _WheelGameState();
}

class _WheelGameState extends ConsumerState<_WheelGame> {
  _Preset _preset = _Preset.food;
  double _turns = 0;
  bool _spinning = false;
  int? _pending;
  int? _result;
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _spin(int count) {
    if (_spinning || count < Wheel.minOptions) return;
    final k = widget.random.nextInt(count);
    setState(() {
      _turns = Wheel.target(_turns, k, count, widget.random);
      _spinning = true;
      _pending = k;
      _result = null;
    });
  }

  void _spinDone() {
    if (!_spinning) return;
    setState(() {
      _spinning = false;
      _result = _pending;
    });
  }

  Future<void> _save(Map<String, List<String>> all, List<String> next) {
    setState(() => _result = null);
    return ref
        .read(settingsRepositoryProvider)
        .set(_wheelListsKey, jsonEncode({...all, _preset.name: next}));
  }

  Future<void> _saveColors(WheelColors w) => ref
      .read(settingsRepositoryProvider)
      .set(_wheelColorsKey, jsonEncode(w.toJson()));

  void _add(Map<String, List<String>> all, List<String> options) {
    final v = _draft.text.trim();
    if (v.isEmpty || _spinning || options.length >= Wheel.maxOptions) return;
    _draft.clear();
    if (options.any((o) => o.toLowerCase() == v.toLowerCase())) return;
    _save(all, [...options, v]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final all = ref.watch(wheelListsProvider).value ?? const {};
    final colors = ref.watch(wheelColorsProvider).value ?? const WheelColors();
    final options = all[_preset.name] ?? _preset.defaults(l);
    final n = options.length;
    final done = !_spinning && _result != null && _result! < n;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in _Preset.values)
              ChoiceChip(
                label: Text(p.label(l)),
                selected: p == _preset,
                onSelected: _spinning
                    ? null
                    : (_) => setState(() {
                        _preset = p;
                        _result = null;
                      }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 288,
            height: 300,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 12,
                  child: Semantics(
                    label: options.join(', '),
                    child: AnimatedRotation(
                      turns: _turns,
                      duration: reduceMotion
                          ? const Duration(milliseconds: 1)
                          : const Duration(milliseconds: 3300),
                      curve: const Cubic(.12, .7, .12, 1),
                      onEnd: _spinDone,
                      child: Container(
                        width: 288,
                        height: 288,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface,
                          boxShadow: cardShadow(c),
                        ),
                        child: CustomPaint(
                          painter: _WheelPainter(
                            options: options,
                            slices: _slices(c, colors),
                            style: Theme.of(context).textTheme.labelMedium!
                                .copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12 + 144 - 38,
                  child: FilledButton(
                    onPressed: () => _spin(n),
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      fixedSize: const Size(76, 76),
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: c.surface, width: 6),
                    ),
                    child: Text(
                      _spinning ? '…' : l.gameSpin,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(26, 22),
                  painter: _PinPainter(c.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          child: Row(
            children: [
              Mascot(done ? MascotPose.senang : MascotPose.halo, size: 68),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _spinning
                            ? l.gameSpinning
                            : done
                            ? l.gameNyawPicks
                            : l.gameReady,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      Text(
                        _spinning
                            ? l.gameWait
                            : done
                            ? options[_result!]
                            : l.gameTapSpin,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (done) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: () => _spin(n),
                              child: Text(l.gameSpinAgain),
                            ),
                            if (_preset.isSpending)
                              FilledButton(
                                onPressed: () => TxFormScreen.open(context),
                                child: Text(l.gameRecordExpense),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.gameWheelItems,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    l.gameWheelCount(n, Wheel.maxOptions),
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < n; i++)
                    InputChip(
                      label: Text(options[i]),
                      deleteButtonTooltipMessage: l.gameRemoveOption(
                        options[i],
                      ),
                      onDeleted: n > Wheel.minOptions && !_spinning
                          ? () => _save(all, [
                              for (var j = 0; j < n; j++)
                                if (j != i) options[j],
                            ])
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draft,
                      enabled: n < Wheel.maxOptions,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(Wheel.maxLabelLength),
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(all, options),
                      decoration: InputDecoration(hintText: l.gameWheelAddHint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: n < Wheel.maxOptions
                        ? () => _add(all, options)
                        : null,
                    child: Text(l.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _WheelColorsCard(
          colors: colors,
          enabled: !_spinning,
          onChanged: _saveColors,
        ),
      ],
    );
  }
}

/// Kartu pilih palet roda + atur warna kustom per slot.
class _WheelColorsCard extends StatefulWidget {
  const _WheelColorsCard({
    required this.colors,
    required this.enabled,
    required this.onChanged,
  });

  final WheelColors colors;
  final bool enabled;
  final ValueChanged<WheelColors> onChanged;

  @override
  State<_WheelColorsCard> createState() => _WheelColorsCardState();
}

class _WheelColorsCardState extends State<_WheelColorsCard> {
  int _slot = 0;

  void _setSlot(String hex) =>
      widget.onChanged(widget.colors.withSlot(_slot, hex));

  Future<void> _pickOther() async {
    final hex = await CustomAccentSheet.open(
      context,
      initial: hexColor(widget.colors.custom[_slot]),
      title: context.l10n.gameWheelSlot(_slot + 1),
      accentPreview: false,
    );
    if (hex != null && mounted) _setSlot(hex);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final w = widget.colors;
    final on = widget.enabled;
    final current = w.custom[_slot];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.gameWheelColors,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _paletteName(l, w.palette),
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 72,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            children: [
              for (final p in WheelColors.palettes)
                _PaletteTile(
                  name: _paletteName(l, p),
                  colors: [for (final s in _slices(c, w, p)) s.$1],
                  selected: p == w.palette,
                  onTap: on ? () => widget.onChanged(w.withPalette(p)) : null,
                ),
            ],
          ),
          if (w.isCustom) ...[
            Divider(height: 24, color: c.line),
            Text(
              l.gameWheelCustomHint,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var k = 0; k < w.custom.length; k++)
                  Expanded(
                    child: _SlotButton(
                      number: k + 1,
                      color: hexColor(w.custom[k]),
                      selected: k == _slot,
                      onTap: () => setState(() => _slot = k),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              children: [
                for (final h in _swatches)
                  _SwatchButton(
                    hex: h,
                    selected: h == current,
                    onTap: on ? () => _setSlot(h) : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: on ? _pickOther : null,
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: Text(l.gameWheelOtherColor),
                ),
                const Spacer(),
                TextButton(
                  onPressed: on
                      ? () => widget.onChanged(w.resetCustom())
                      : null,
                  child: Text(l.gameWheelResetColors),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l.gameWheelColorsNote,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.name,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final List<Color> colors;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? c.primary : Colors.transparent,
        width: 2,
      ),
    );
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? c.primarySoft : c.subtle,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size.square(30),
                painter: _SwatchPainter(colors, ring: c.surface),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? c.onPrimarySoft : c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lingkaran mini berisi warna-warna palet.
class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.colors, {required this.ring});

  final List<Color> colors;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r);
    final sweep = 2 * math.pi / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = colors[i],
      );
    }
    canvas.drawCircle(
      Offset(r, r),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      !listEquals(old.colors, colors) || old.ring != ring;
}

/// Tombol slot kustom bernomor.
class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.number,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: context.l10n.gameWheelSlot(number),
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: c.line),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _labelOn(color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contoh warna cepat untuk slot terpilih.
class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: context.l10n.gameWheelUseColor(hex),
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(2),
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

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.options,
    required this.slices,
    required this.style,
  });

  final List<String> options;

  /// (warna irisan, warna tulisan) per slot.
  final List<(Color, Color)> slices;
  final TextStyle style;

  (Color, Color) _slice(int i, int n) =>
      slices[Wheel.colorSlot(i, n, slots: slices.length)];

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final n = options.length;
    final sweep = 2 * math.pi / n;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = _slice(i, n).$1,
      );
    }
    final maxWidth = math.min(r * 0.66, 2 * r * 0.8 * math.sin(sweep / 2));
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: options[i],
          style: style.copyWith(color: _slice(i, n).$2),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      canvas
        ..save()
        ..translate(r, r)
        ..rotate((i + 0.5) * sweep);
      tp.paint(canvas, Offset(-tp.width / 2, -r * 0.84));
      canvas.restore();
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      !listEquals(old.options, options) ||
      !listEquals(old.slices, slices) ||
      old.style != style;
}

/// Jarum segitiga di atas roda.
class _PinPainter extends CustomPainter {
  _PinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

class _RpsGame extends StatefulWidget {
  const _RpsGame({required this.random});

  final math.Random random;

  @override
  State<_RpsGame> createState() => _RpsGameState();
}

class _RpsGameState extends State<_RpsGame> {
  Hand? _me;
  Hand? _nyaw;
  bool _counting = false;
  Timer? _timer;
  int _win = 0, _lose = 0, _tie = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play(Hand h) {
    if (_counting) return;
    setState(() {
      _me = h;
      _nyaw = null;
      _counting = true;
    });
    _timer = Timer(const Duration(milliseconds: 700), () {
      final y = Hand.values[widget.random.nextInt(Hand.values.length)];
      setState(() {
        _nyaw = y;
        _counting = false;
        switch (playRps(h, y)) {
          case RpsOutcome.win:
            _win++;
          case RpsOutcome.lose:
            _lose++;
          case RpsOutcome.tie:
            _tie++;
        }
      });
    });
  }

  void _reset() {
    if (_counting) return;
    setState(() {
      _me = null;
      _nyaw = null;
      _win = _lose = _tie = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final outcome = _me == null || _counting || _nyaw == null
        ? null
        : playRps(_me!, _nyaw!);
    final (statusText, statusBg, statusFg) = switch (outcome) {
      null => (
        _counting ? l.gameCounting : l.gamePickHand,
        c.primarySoft,
        c.onPrimarySoft,
      ),
      RpsOutcome.win => (l.gameWin, c.primarySoft, c.onPrimarySoft),
      RpsOutcome.lose => (l.gameLose, c.soft(c.expense), c.fg(c.expense)),
      RpsOutcome.tie => (l.gameTie, c.warnSoft, c.onWarnSoft),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _HandBox(label: l.gameYou, hand: _me),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: c.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _HandBox(
                      label: 'Nyaw',
                      hand: _counting ? null : _nyaw,
                      pending: _counting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final h in Hand.values) ...[
              if (h != Hand.values.first) const SizedBox(width: 10),
              Expanded(
                child: _HandButton(
                  hand: h,
                  selected: h == _me,
                  onTap: () => _play(h),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.gameScore,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _reset, child: Text(l.gameResetScore)),
                ],
              ),
              Row(
                children: [
                  for (final (v, label) in [
                    (_win, l.gameYou),
                    (_tie, l.gameTieLabel),
                    (_lose, 'Nyaw'),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$v',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _handIcon(Hand h) => switch (h) {
  Hand.rock => Icons.sports_mma_outlined,
  Hand.scissors => Icons.content_cut_rounded,
  Hand.paper => Icons.back_hand_outlined,
};

String _handName(AppLocalizations l, Hand h) => switch (h) {
  Hand.rock => l.gameRock,
  Hand.scissors => l.gameScissors,
  Hand.paper => l.gamePaper,
};

class _HandBox extends StatelessWidget {
  const _HandBox({required this.label, this.hand, this.pending = false});

  final String label;
  final Hand? hand;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = hand;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: c.subtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 6),
          Icon(
            h != null
                ? _handIcon(h)
                : pending
                ? Icons.more_horiz_rounded
                : Icons.question_mark_rounded,
            size: 40,
            color: c.ink,
          ),
          const SizedBox(height: 6),
          Text(
            h != null ? _handName(context.l10n, h) : (pending ? '…' : '?'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HandButton extends StatelessWidget {
  const _HandButton({
    required this.hand,
    required this.selected,
    required this.onTap,
  });

  final Hand hand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onPrimarySoft : c.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow(c),
      ),
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_handIcon(hand), size: 34, color: fg),
                const SizedBox(height: 6),
                Text(
                  _handName(context.l10n, hand),
                  style: TextStyle(
                    color: fg,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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
