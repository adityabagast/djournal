import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/platform/platform_info.dart';
import '../../core/theme.dart';
import '../../data/update/update_controller.dart';
import '../../data/update/update_service.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../update/update_card.dart';
import '../update/whats_new_sheet.dart';

/// Bagian "Tentang" di Pengaturan: versi, cek update, dan tautan rilis.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  static const _testerUrl =
      'https://appdistribution.firebase.dev/i/7f0a29e4b1386d45';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final info = ref.watch(appVersionProvider).value;
    final s = ref.watch(updateProvider);
    final auto = ref.watch(updateAutoProvider).value ?? true;
    final lastCheck = ref.watch(updateLastCheckProvider).value;
    final ctrl = ref.read(updateProvider.notifier);
    final divider = Divider(height: 1, color: c.divider);
    const titleStyle = TextStyle(fontWeight: FontWeight.w500);
    final subStyle = TextStyle(fontSize: 12, color: c.muted);

    String when(DateTime t) => toLocalDate(t) == toLocalDate(DateTime.now())
        ? '${l.today.toLowerCase()}, ${hhmm(t)}'
        : DateFormat('d MMM y, HH.mm', context.localeTag).format(t);

    final Widget status = switch (s.phase) {
      UpdatePhase.checking => Row(
        children: [
          const Mascot(MascotPose.mencari, size: 40),
          const SizedBox(width: 10),
          Text(l.updateChecking),
        ],
      ),
      UpdatePhase.available ||
      UpdatePhase.downloading ||
      UpdatePhase.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Mascot(
                s.phase == UpdatePhase.downloading
                    ? MascotPose.sinkron
                    : MascotPose.senang,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.phase == UpdatePhase.downloading
                          ? l.updateDownloading(s.release!.version)
                          : l.updateVersionAvailable(s.release!.version),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () => WhatsNewSheet.open(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l.updateWhatsNew),
                    ),
                  ],
                ),
              ),
              if (s.phase == UpdatePhase.available)
                FilledButton(
                  onPressed: ctrl.download,
                  child: Text(l.updateDownload),
                ),
              if (s.phase == UpdatePhase.ready)
                FilledButton(
                  onPressed: ctrl.install,
                  child: Text(l.updateInstallNow),
                ),
            ],
          ),
          if (s.phase == UpdatePhase.downloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                // Tanpa ukuran file, tampilkan animasi tak tentu.
                value: (s.release!.apkSize ?? 0) > 0 && s.progress > 0
                    ? s.progress
                    : null,
                minHeight: 8,
                backgroundColor: c.track,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.updateDownloadProgress(
                      formatMegabytes(
                        context,
                        ((s.release!.apkSize ?? 0) * s.progress).round(),
                      ),
                      formatMegabytes(context, s.release!.apkSize ?? 0),
                    ),
                    style: subStyle,
                  ),
                ),
                TextButton(
                  onPressed: ctrl.cancelDownload,
                  child: Text(l.updateCancel),
                ),
              ],
            ),
          ],
          if (updateErrorText(l, s.error) case final error?) ...[
            const SizedBox(height: 6),
            Text(error, style: subStyle.copyWith(color: c.expense)),
          ],
        ],
      ),
      UpdatePhase.upToDate => Row(
        children: [
          const Mascot(MascotPose.senang, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.updateUpToDate,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: ctrl.check, child: Text(l.updateCheckNow)),
        ],
      ),
      UpdatePhase.idle => Row(
        children: [
          Expanded(
            child: Text(
              s.error != null
                  ? updateCheckErrorText(l, s.error)
                  : lastCheck == null
                  ? ''
                  : l.updateLastChecked(when(lastCheck)),
              style: subStyle.copyWith(
                color: s.error != null ? c.expense : c.muted,
              ),
            ),
          ),
          FilledButton(onPressed: ctrl.check, child: Text(l.updateCheckNow)),
        ],
      ),
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: c.primarySoft,
              child: const Mascot(MascotPose.halo, size: 38),
            ),
            title: const Text(
              'Nyawtat',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: info == null
                ? null
                : Text(
                    l.aboutVersion(info.version, info.buildNumber),
                    style: subStyle,
                  ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: c.subtle,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                if (updateErrorText(l, s.error) case final e?
                    when s.phase != UpdatePhase.idle)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(e, style: subStyle.copyWith(color: c.expense)),
                  ),
              ],
            ),
          ),
          if (PlatformInfo.isAndroid)
            SwitchListTile(
              value: auto,
              onChanged: ctrl.setAuto,
              title: Text(l.updateAuto, style: titleStyle),
              subtitle: Text(l.updateAutoSub, style: subStyle),
              activeThumbColor: c.onPrimary,
              activeTrackColor: c.primary,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(l.updatePrivacyNote, style: subStyle),
          ),
          divider,
          ListTile(
            title: Text(l.aboutReleases, style: titleStyle),
            trailing: Icon(Icons.chevron_right, color: c.faint),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/${UpdateService.repo}/releases'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          divider,
          ListTile(
            title: Text(l.aboutTester, style: titleStyle),
            subtitle: Text(l.aboutTesterSub, style: subStyle),
            trailing: Icon(Icons.chevron_right, color: c.faint),
            onTap: () => launchUrl(
              Uri.parse(_testerUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
