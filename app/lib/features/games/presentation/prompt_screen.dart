import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../domain/games.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../journal/presentation/entry_form_screen.dart';
import '../../../core/tokens.dart';

enum PromptCategory { gratitude, reflection, relax, dreams }

extension on PromptCategory {
  String label(AppLocalizations l) => switch (this) {
    PromptCategory.gratitude => l.gamePromptGratitude,
    PromptCategory.reflection => l.gamePromptReflection,
    PromptCategory.relax => l.gamePromptRelax,
    PromptCategory.dreams => l.gamePromptDreams,
  };

  List<String> questions(AppLocalizations l) => switch (this) {
    PromptCategory.gratitude => l.gamePromptGratitudeList,
    PromptCategory.reflection => l.gamePromptReflectionList,
    PromptCategory.relax => l.gamePromptRelaxList,
    PromptCategory.dreams => l.gamePromptDreamsList,
  }.split('|');
}

/// Kocok ide: pertanyaan acak untuk memulai tulisan jurnal.
class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key, this.random});

  /// Bisa diisi di tes supaya pertanyaannya pasti.
  final math.Random? random;

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const PromptScreen()));

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  late final math.Random _random = widget.random ?? math.Random();
  PromptCategory _cat = PromptCategory.gratitude;
  final _bags = <PromptCategory, ShuffleBag>{};

  /// Pertanyaan yang tampil; null = belum dipilih (dipilih acak saat dibangun).
  int? _index;
  bool _shuffling = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ShuffleBag _bag(int count) =>
      _bags.putIfAbsent(_cat, () => ShuffleBag(count, _random));

  void _shuffle(int count) {
    if (_shuffling) return;
    setState(() => _shuffling = true);
    var ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 90), (t) {
      ticks++;
      if (ticks < 6) {
        // Hanya efek kocokan; hasilnya baru ditentukan di akhir.
        setState(() => _index = _random.nextInt(count));
        return;
      }
      t.cancel();
      setState(() {
        _index = _bag(count).next();
        _shuffling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final questions = _cat.questions(l);
    _index ??= _bag(questions.length).next();
    final question = questions[_index! % questions.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.gamePrompt,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xs, AppSpace.xl, AppSpace.xxxl),
        children: [
          Text(
            l.gamePromptDesc,
            style: TextStyle(color: c.muted, fontSize: AppFontSize.body),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in PromptCategory.values)
                ChoiceChip(
                  label: Text(cat.label(l)),
                  selected: cat == _cat,
                  onSelected: _shuffling
                      ? null
                      : (_) => setState(() {
                          _cat = cat;
                          _index = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 22, AppSpace.lg, AppSpace.lg),
            child: Column(
              children: [
                const Mascot(MascotPose.menulis, size: 104),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l.gamePromptLabel,
                  style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 150),
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      child: AnimatedOpacity(
                        opacity: _shuffling ? 0.45 : 1,
                        duration: AppMotion.short,
                        child: Text(
                          question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: AppFontSize.display,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _shuffling
                      ? null
                      : () => _shuffle(questions.length),
                  child: Text(l.gamePromptShuffle),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _shuffling
                      ? null
                      : () => EntryFormScreen.open(
                          context,
                          initialTitle: question,
                        ),
                  child: Text(l.gamePromptWrite),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            l.gamePromptNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
          ),
        ],
      ),
    );
  }
}
