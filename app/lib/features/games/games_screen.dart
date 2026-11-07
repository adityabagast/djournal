import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/games.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../money/tx_form_screen.dart';

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
                            fills: [
                              for (final base in const [
                                Color(0xFF1F5F4E),
                                Color(0xFFC2410C),
                                Color(0xFF1D4E89),
                                Color(0xFF9A5B12),
                                Color(0xFF7E3AA8),
                                Color(0xFFBE185D),
                              ])
                                c.soft(base),
                            ],
                            style: Theme.of(context).textTheme.labelMedium!
                                .copyWith(
                                  color: c.ink,
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
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.options,
    required this.fills,
    required this.style,
  });

  final List<String> options;
  final List<Color> fills;
  final TextStyle style;

  /// Warna irisan; irisan terakhir tidak boleh sama dengan irisan pertama.
  Color _fill(int i, int n) {
    final k = i % fills.length;
    return i == n - 1 && n > 1 && k == 0 ? fills[2] : fills[k];
  }

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
        Paint()..color = _fill(i, n),
      );
    }
    final maxWidth = math.min(r * 0.66, 2 * r * 0.8 * math.sin(sweep / 2));
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(text: options[i], style: style),
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
      !listEquals(old.fills, fills) ||
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
