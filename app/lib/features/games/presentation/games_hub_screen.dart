import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import 'games_screen.dart';
import 'memory_screen.dart';
import 'prompt_screen.dart';
import '../../../core/tokens.dart';

const _blue = Color(0xFF1D4E89);

/// Halaman Permainan: empat permainan kecil untuk rehat.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const GamesHubScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final best = ref.watch(memoryBestProvider).value;

    final tiles = [
      _GameTile(
        icon: Icons.donut_large_rounded,
        fg: c.onPrimarySoft,
        bg: c.primarySoft,
        title: l.gameWheel,
        desc: l.gameWheelDesc,
        onTap: () => WheelRpsScreen.open(context),
      ),
      _GameTile(
        icon: Icons.content_cut_rounded,
        fg: c.onWarnSoft,
        bg: c.warnSoft,
        title: l.gameRps,
        desc: l.gameRpsDesc,
        onTap: () => WheelRpsScreen.open(context, initialTab: 1),
      ),
      _GameTile(
        icon: Icons.style_outlined,
        fg: c.fg(c.expense),
        bg: c.soft(c.expense),
        title: l.gameMemory,
        desc: l.gameMemoryDesc,
        badge: best == null ? null : l.gameMemoryRecord(best),
        onTap: () => MemoryScreen.open(context),
      ),
      _GameTile(
        icon: Icons.casino_outlined,
        fg: c.fg(_blue),
        bg: c.soft(_blue),
        title: l.gamePrompt,
        desc: l.gamePromptDesc,
        onTap: () => PromptScreen.open(context),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.games,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xs, AppSpace.xl, AppSpace.xxxl),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.lg, AppSpace.lg, 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Mascot(MascotPose.tidur, size: 92),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.gameHubTitle,
                          style: TextStyle(
                            color: c.onPrimarySoft,
                            fontSize: AppFontSize.heading,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          l.gameHubHint,
                          style: TextStyle(
                            color: c.onPrimarySoft,
                            fontSize: AppFontSize.body,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          for (var i = 0; i < tiles.length; i += 2) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[i]),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          const SizedBox(height: AppSpace.xs),
          Text(
            l.gameHubFootnote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.desc,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final String title;
  final String desc;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: cardShadow(c),
      ),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  desc,
                  style: TextStyle(fontSize: AppFontSize.meta, height: 1.45, color: c.muted),
                ),
                const SizedBox(height: AppSpace.sm),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w600,
                        color: c.onPrimarySoft,
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

/// Kartu "Rehat sebentar" di Hari Ini: pintu masuk ke permainan.
class RestCard extends StatelessWidget {
  const RestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final items = [
      (
        Icons.donut_large_rounded,
        c.onPrimarySoft,
        c.primarySoft,
        l.gameShortWheel,
        () => WheelRpsScreen.open(context),
      ),
      (
        Icons.content_cut_rounded,
        c.onWarnSoft,
        c.warnSoft,
        l.gameShortRps,
        () => WheelRpsScreen.open(context, initialTab: 1),
      ),
      (
        Icons.style_outlined,
        c.fg(c.expense),
        c.soft(c.expense),
        l.gameShortMemory,
        () => MemoryScreen.open(context),
      ),
      (
        Icons.casino_outlined,
        c.fg(_blue),
        c.soft(_blue),
        l.gameShortPrompt,
        () => PromptScreen.open(context),
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FitText(
                  l.gameRest,
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () => GamesHubScreen.open(context),
                  child: FitText(l.gameRestAll),
                ),
              ),
            ],
          ),
          Row(
            children: [
              for (final (icon, fg, bg, label, onTap) in items)
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: fg, size: 21),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          FitText(
                            label,
                            alignment: Alignment.center,
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
