import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../../providers.dart';
import '../../backup/presentation/backup_screen.dart';
import '../providers/account_controller.dart';
import 'account_card.dart';
import 'account_sheets.dart';
import 'sign_in_screen.dart';

/// Pengaturan › Akun: status server dan Google Drive, sync manual, dan keluar.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AccountScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final account = ref.watch(accountProvider);
    final drive = ref.watch(googleDriveProvider);
    final needsLogin = needsServerLogin(account);
    final server = serverStatus(context, l, account);
    const titleStyle = TextStyle(
      fontSize: AppFontSize.bodyLg,
      fontWeight: FontWeight.w500,
    );
    final subStyle = TextStyle(fontSize: AppFontSize.meta, color: c.muted);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.account,
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
        children: [
          if (backendConfigured) ...[
            ServiceCard(
              title: l.serverName,
              tag: account.loggedIn ? l.googleDriveConnected : l.serverTagOff,
              tagOk: account.loggedIn && server.ok,
              status: server.text,
              children: [
                FilledButton(
                  onPressed: account.syncing
                      ? null
                      : () => needsLogin
                            ? SignInScreen.open(context)
                            : _syncNow(context, ref),
                  child: Text(
                    needsLogin
                        ? l.serverSignInTitle
                        : account.error != null
                        ? l.retry
                        : l.syncNow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          ServiceCard(
            title: 'Google Drive',
            tag: drive.isConnected
                ? l.googleDriveConnected
                : l.googleDriveNotConnected,
            tagOk: drive.isConnected,
            status: driveStatus(context, l, drive).text,
            children: [
              OutlinedButton(
                onPressed: () => drive.isConnected
                    ? BackupScreen.open(context)
                    : connectDrive(context, ref),
                child: Text(drive.isConnected ? l.openBackup : l.connect),
              ),
            ],
          ),
          if (drive.isConnected || account.loggedIn) ...[
            const SizedBox(height: AppSpace.xl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xs,
                0,
                AppSpace.xs,
                AppSpace.sm,
              ),
              child: Text(
                l.signOut.toUpperCase(),
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                ),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Column(
                children: [
                  if (drive.isConnected)
                    ListTile(
                      title: Text(l.disconnectDrive, style: titleStyle),
                      subtitle: Text(l.disconnectDriveSub, style: subStyle),
                      onTap: () => _disconnectDrive(context, ref),
                    ),
                  if (account.loggedIn)
                    ListTile(
                      title: Text(
                        l.signOutServer,
                        style: titleStyle.copyWith(color: c.expense),
                      ),
                      subtitle: Text(l.signOutServerSub, style: subStyle),
                      onTap: () => _signOutServer(context, ref),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sinkron manual dari tombol; sinkron otomatis tidak memunculkan snackbar.
  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    await ref.read(accountProvider.notifier).sync();
    if (!context.mounted || ref.read(accountProvider).error != null) return;
    showMascotSnackBar(
      context,
      MascotPose.sinkron,
      context.l10n.toastSynced,
      aboveDock: false,
    );
  }

  Future<void> _disconnectDrive(BuildContext context, WidgetRef ref) async {
    final ok = await DriveDisconnectSheet.show(context);
    if (ok == true) await ref.read(googleDriveProvider.notifier).signOut();
  }

  /// Keluar dari server menghapus data di perangkat: hanya jalan setelah
  /// user mencentang persetujuan.
  Future<void> _signOutServer(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountProvider.notifier);
    final unsynced = await controller.hasUnsyncedChanges();
    if (!context.mounted) return;
    final action = await ServerSignOutSheet.show(context, unsynced: unsynced);
    if (action == ServerSignOutAction.signOut) {
      await controller.signOut();
    } else if (action == ServerSignOutAction.backup && context.mounted) {
      await BackupScreen.open(context);
    }
  }
}

/// Hubungkan Google Drive; kegagalan ditampilkan sebagai snackbar.
Future<void> connectDrive(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(googleDriveProvider.notifier).signIn();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(googleSignInErrorText(e))));
  }
}

/// Kartu satu layanan (server / Drive): judul, label status, dan tombol.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.tag,
    required this.tagOk,
    required this.status,
    required this.children,
  });

  final String title;
  final String tag;
  final bool tagOk;
  final String status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSize.bodyLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: tagOk ? c.primarySoft : c.warnSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: tagOk ? c.primary : c.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            status,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpace.md),
          ...children,
        ],
      ),
    );
  }
}
