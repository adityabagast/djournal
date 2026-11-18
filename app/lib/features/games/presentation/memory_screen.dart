import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../domain/games.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';

/// Kunci app_settings (lokal) untuk rekor memory: jumlah langkah tersedikit.
const memoryBestKey = 'game_memory_best';

final memoryBestProvider = StreamProvider<int?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(memoryBestKey)
      .map((v) => v == null ? null : int.tryParse(v)),
);

const _poses = [
  MascotPose.halo,
  MascotPose.menulis,
  MascotPose.koin,
  MascotPose.senang,
  MascotPose.sedih,
  MascotPose.tidur,
];

/// Memory kartu: cocokkan 6 pasang pose Nyaw dengan langkah sesedikit mungkin.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key, this.random});

  /// Bisa diisi di tes supaya urutan kartu pasti.
  final math.Random? random;

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const MemoryScreen()));

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  late final math.Random _random = widget.random ?? math.Random();
  late MemoryGame _game = MemoryGame(_random);
  Timer? _hide;

  /// Rekor sebelum ronde ini selesai, untuk membedakan "rekor baru".
  bool _newBest = false;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _flip(int i) {
    if (!_game.flip(i)) return;
    setState(() {});
    if (_game.mismatch) {
      _hide = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(_game.hideMismatch);
      });
    }
    if (_game.won) _finish();
  }

  Future<void> _finish() async {
    final best = ref.read(memoryBestProvider).value;
    if (best == null || _game.moves < best) {
      _newBest = true;
      await ref
          .read(settingsRepositoryProvider)
          .set(memoryBestKey, '${_game.moves}');
    }
  }

  void _again() {
    _hide?.cancel();
    setState(() {
      _game = MemoryGame(_random);
      _newBest = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final best = ref.watch(memoryBestProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.gameMemory,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(l.gameMemorySub, style: TextStyle(color: c.muted, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            spacing: 10,
            children: [
              _Stat(value: '${_game.moves}', label: l.gameMoves),
              _Stat(
                value: '${_game.matched.length ~/ 2}/${MemoryGame.pairs}',
                label: l.gamePairs,
              ),
              _Stat(value: best == null ? '–' : '$best', label: l.gameBest),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 110 / 112,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < _game.deck.length; i++)
                _MemoryCard(
                  pose: _poses[_game.deck[i]],
                  faceUp: _game.open.contains(i) || _game.matched.contains(i),
                  matched: _game.matched.contains(i),
                  label: _game.open.contains(i) || _game.matched.contains(i)
                      ? l.gameCardOpen
                      : l.gameCardClosed(i + 1),
                  onTap: () => _flip(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_game.won)
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  const Mascot(MascotPose.senang, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _newBest
                                ? l.gameMemoryNewBest(_game.moves)
                                : l.gameMemoryDone(_game.moves),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l.gameMemoryBestLine(
                              math.min(best ?? _game.moves, _game.moves),
                            ),
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilledButton(onPressed: _again, child: Text(l.gamePlayAgain)),
                ],
              ),
            )
          else
            Center(
              child: OutlinedButton(
                onPressed: _again,
                child: Text(l.gameReshuffle),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: cardShadow(c),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(label, style: TextStyle(fontSize: 11.5, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.pose,
    required this.faceUp,
    required this.matched,
    required this.label,
    required this.onTap,
  });

  final MascotPose pose;
  final bool faceUp;
  final bool matched;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: cardShadow(c),
        ),
        child: Material(
          color: matched
              ? c.primarySoft
              : faceUp
              ? c.surface
              : c.primary,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: faceUp
                  ? Mascot(pose, size: 76)
                  : Icon(
                      Icons.favorite_rounded,
                      color: c.onPrimary.withValues(alpha: 0.9),
                      size: 30,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
