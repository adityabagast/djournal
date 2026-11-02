import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/update/update_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import 'whats_new_sheet.dart';

/// "24,0 MB" sesuai bahasa app.
String formatMegabytes(BuildContext context, int bytes) =>
    '${NumberFormat('#,##0.0', context.localeTag).format(bytes / 1048576)} MB';

/// Pesan untuk [UpdateState.error].
String? updateErrorText(AppLocalizations l, String? error) => switch (error) {
  'network' => l.updateErrorNetwork,
  'checksum' => l.updateErrorChecksum,
  'permission' => l.updateErrorPermission,
  'source' => l.updateErrorSource,
  _ => null,
};

/// Kartu "Ada versi baru" di atas Hari Ini: tawaran → unduhan → siap pasang.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(updateProvider);
    final r = s.release;
    if (!s.showCard || r == null) return const SizedBox.shrink();
    final l = context.l10n;
    final c = context.colors;
    final ctrl = ref.read(updateProvider.notifier);
    final error = updateErrorText(l, s.error);
    final small = TextStyle(fontSize: 12.5, height: 1.45, color: c.muted);

    Future<void> snooze() async {
      await ctrl.snooze();
      if (context.mounted) {
        showMascotSnackBar(context, MascotPose.senang, l.updateSnoozed);
      }
    }

    final (pose, title, content) = switch (s.phase) {
      UpdatePhase.downloading => (
        MascotPose.sinkron,
        l.updateDownloading(r.version),
        <Widget>[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.progress,
              minHeight: 8,
              backgroundColor: c.track,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.updateDownloadProgress(
              formatMegabytes(context, ((r.apkSize ?? 0) * s.progress).round()),
              formatMegabytes(context, r.apkSize ?? 0),
            ),
            style: small,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: ctrl.cancelDownload,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(l.updateCancel),
            ),
          ),
        ],
      ),
      UpdatePhase.ready => (
        MascotPose.senang,
        l.updateReadyTitle,
        <Widget>[
          const SizedBox(height: 4),
          Text(l.updateReadyBody, style: small),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: ctrl.install,
                child: Text(l.updateInstallNow),
              ),
              FilledButton.tonal(onPressed: snooze, child: Text(l.updateLater)),
            ],
          ),
        ],
      ),
      _ => (
        MascotPose.senang,
        l.updateAvailableTitle,
        <Widget>[
          const SizedBox(height: 4),
          Text(
            l.updateAvailableBody(
              r.version,
              r.apkSize == null
                  ? ''
                  : ' (${formatMegabytes(context, r.apkSize!)})',
            ),
            style: small,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: ctrl.download,
                child: Text(l.updateDownload),
              ),
              FilledButton.tonal(
                onPressed: () => WhatsNewSheet.open(context),
                child: Text(l.updateWhatsNew),
              ),
            ],
          ),
        ],
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(6, 14, 14, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Mascot(pose, size: 80),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (s.phase == UpdatePhase.available)
                          IconButton(
                            tooltip: l.updateLater,
                            onPressed: snooze,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close, size: 18, color: c.muted),
                          ),
                      ],
                    ),
                    ...content,
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error, style: small.copyWith(color: c.expense)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
