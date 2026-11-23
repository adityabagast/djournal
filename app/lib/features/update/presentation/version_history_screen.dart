import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../domain/changelog.dart';
import '../providers/changelog_provider.dart';
import '../providers/update_controller.dart';
import 'whats_new_sheet.dart';

/// Pengaturan › Tentang › Riwayat versi. Isinya dari CHANGELOG yang dibawa
/// app, jadi bisa dibuka tanpa internet.
class VersionHistoryScreen extends ConsumerStatefulWidget {
  const VersionHistoryScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const VersionHistoryScreen()));

  @override
  ConsumerState<VersionHistoryScreen> createState() =>
      _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends ConsumerState<VersionHistoryScreen> {
  /// Pilihan user; versi lain memakai keadaan bawaan.
  final _toggled = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final entries = ref.watch(changelogProvider).value ?? const [];
    final mine = ref.watch(appVersionProvider).value?.version;
    final update = ref.watch(updateProvider);
    final hasNew =
        update.release != null &&
        const {
          UpdatePhase.available,
          UpdatePhase.downloading,
          UpdatePhase.ready,
        }.contains(update.phase);

    final openByDefault = entries.any((e) => e.version == mine)
        ? mine
        : entries.firstOrNull?.version;
    final month = DateFormat('MMMM y', context.localeTag);

    final children = <Widget>[
      if (hasNew) ...[
        _NewVersionBanner(version: update.release!.version),
        const SizedBox(height: AppSpace.lg),
      ],
    ];
    String? lastMonth;
    for (final e in entries) {
      final name = month.format(e.date);
      if (name != lastMonth) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xs,
              AppSpace.sm,
              AppSpace.xs,
              AppSpace.sm,
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppFontSize.meta,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
            ),
          ),
        );
        lastMonth = name;
      }
      final open = _toggled[e.version] ?? e.version == openByDefault;
      children
        ..add(
          _VersionCard(
            entry: e,
            mine: e.version == mine,
            open: open,
            onTap: () => setState(() => _toggled[e.version] = !open),
          ),
        )
        ..add(const SizedBox(height: AppSpace.md));
    }
    if (entries.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Text(
            l.historyOffline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSize.meta,
              height: 1.5,
              color: c.muted,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.aboutReleases,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.sm,
          AppSpace.xl,
          AppSpace.xxxl,
        ),
        children: children,
      ),
    );
  }
}

class _NewVersionBanner extends StatelessWidget {
  const _NewVersionBanner({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const Mascot(MascotPose.senang, size: 40),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.updateVersionAvailable(version),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: c.onPrimarySoft,
                  ),
                ),
                Text(
                  l.historyUpdateHint,
                  style: TextStyle(
                    fontSize: AppFontSize.meta,
                    color: c.onPrimarySoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          FilledButton(
            onPressed: () => WhatsNewSheet.open(context),
            child: Text(l.historyView),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.entry,
    required this.mine,
    required this.open,
    required this.onTap,
  });

  final ChangelogEntry entry;
  final bool mine;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final sub = TextStyle(fontSize: AppFontSize.meta, color: c.muted);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpace.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                entry.version,
                                style: const TextStyle(
                                  fontSize: AppFontSize.title,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (mine)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.sm,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.primarySoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    l.historyMine,
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      fontWeight: FontWeight.w600,
                                      color: c.onPrimarySoft,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            entry.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: sub,
                          ),
                          Text(
                            DateFormat(
                              'd MMM',
                              context.localeTag,
                            ).format(entry.date),
                            style: sub,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: c.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open) ...[
            Divider(height: 1, color: c.divider),
            for (final s in entry.sections) ...[
              const SizedBox(height: AppSpace.md),
              if (s.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Text(
                    s.title!,
                    style: TextStyle(
                      fontSize: AppFontSize.meta,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
              for (final line in s.lines)
                Padding(
                  padding: EdgeInsets.only(
                    left: line.depth * AppSpace.lg,
                    bottom: AppSpace.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•', style: TextStyle(height: 1.5, color: c.muted)),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          line.text,
                          style: const TextStyle(
                            fontSize: AppFontSize.body,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}
