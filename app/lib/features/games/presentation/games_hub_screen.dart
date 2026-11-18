import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import 'games_screen.dart';
import 'memory_screen.dart';
import 'prompt_screen.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 14, 18, 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Mascot(MascotPose.tidur, size: 92),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.gameHubTitle,
                          style: TextStyle(
                            color: c.onPrimarySoft,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.gameHubHint,
                          style: TextStyle(
                            color: c.onPrimarySoft,
                            fontSize: 13,
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
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: tiles,
          ),
          const SizedBox(height: 16),
          Text(
            l.gameHubFootnote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.muted),
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: cardShadow(c),
      ),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, height: 1.45, color: c.muted),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11.5,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.gameRest,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => GamesHubScreen.open(context),
                child: Text(l.gameRestAll),
              ),
            ],
          ),
          Row(
            children: [
              for (final (icon, fg, bg, label, onTap) in items)
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                          const SizedBox(height: 6),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
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
