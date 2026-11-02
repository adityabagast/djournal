import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/platform/platform_info.dart';
import '../../core/theme.dart';
import '../../data/update/update_controller.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import 'update_card.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              const Mascot(MascotPose.senang, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.updateWhatsNewTitle(r.version),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: TextStyle(fontSize: 12.5, color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(r.notes, style: const TextStyle(fontSize: 14, height: 1.55)),
          const SizedBox(height: 16),
          if (inApp)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.subtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                l.updateInstallHint,
                style: TextStyle(fontSize: 12.5, height: 1.5, color: c.muted),
              ),
            ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
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
