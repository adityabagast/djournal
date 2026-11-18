import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/theme.dart';
import '../providers/update_controller.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import 'update_card.dart';
import '../../../core/tokens.dart';

/// Sheet "Apa yang baru": catatan rilis, ukuran, dan tombol unduh.
class WhatsNewSheet extends ConsumerWidget {
  const WhatsNewSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const WhatsNewSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(updateProvider);
    final r = s.release;
    if (r == null) return const SizedBox.shrink();
    final l = context.l10n;
    final c = context.colors;
    final ctrl = ref.read(updateProvider.notifier);
    final inApp = PlatformInfo.isAndroid && r.apkUrl != null;
    final meta = [
      if (r.publishedAt != null)
        l.updateReleased(
          DateFormat(
            'd MMM y',
            context.localeTag,
          ).format(r.publishedAt!.toLocal()),
        ),
      if (r.apkSize != null) formatMegabytes(context, r.apkSize!),
    ].join(' · ');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xxl),
        children: [
          Row(
            children: [
              const Mascot(MascotPose.senang, size: 60),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.updateWhatsNewTitle(r.version),
                      style: const TextStyle(
                        fontSize: AppFontSize.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(r.notes, style: const TextStyle(fontSize: AppFontSize.bodyLg, height: 1.55)),
          const SizedBox(height: AppSpace.lg),
          if (inApp)
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: c.subtle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                l.updateInstallHint,
                style: TextStyle(fontSize: AppFontSize.meta, height: 1.5, color: c.muted),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (s.phase == UpdatePhase.ready) {
                ctrl.install();
              } else if (s.phase != UpdatePhase.downloading) {
                ctrl.download();
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              !inApp
                  ? l.updateOpenRelease
                  : s.phase == UpdatePhase.ready
                  ? l.updateInstallNow
                  : l.updateDownloadAndInstall,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ctrl.snooze();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.updateRemindLater),
          ),
        ],
      ),
    );
  }
}
