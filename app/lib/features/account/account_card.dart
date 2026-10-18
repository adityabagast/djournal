import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/backup_service.dart';
import '../../data/excel_report.dart';
import '../../data/google_drive_service.dart';
import '../../data/sync/account_controller.dart';
import '../../data/sync/backend.dart';
import '../../domain/models/backup_period.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import 'sign_in_screen.dart';

/// Kartu akun di Pengaturan: menampilkan status akun terpadu
/// (Google Drive Backup dan/atau Server Supabase), atau ajakan masuk jika mode tamu.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final account = ref.watch(accountProvider);
    final drive = ref.watch(googleDriveProvider);

    if (account.loading) {
      return const AppCard(child: LinearProgressIndicator());
    }

    // Jika keduanya BELUM terhubung (Mode Tamu / Offline)
    if (!account.loggedIn && !drive.isConnected) {
      if (!backendConfigured && !drive.isConnected) {
        return AppCard(
          child: Text(
            l.backendNotConfigured,
            style: t.bodySmall?.copyWith(color: context.colors.muted),
          ),
        );
      }

      final avatar = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_outline, color: context.colors.primary),
      );

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.guestMode,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.guestModePrompt,
                        style: t.bodySmall?.copyWith(color: context.colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => SignInScreen.open(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l.signInAccount),
            ),
          ],
        ),
      );
    }

    // Jika terhubung minimal salah satu akun (Google Drive dan/atau Server)
    final Widget avatar;
    if (drive.isConnected) {
      final initial = (drive.displayName?.isNotEmpty ?? false)
          ? drive.displayName![0].toUpperCase()
          : (drive.email?.isNotEmpty ?? false)
              ? drive.email![0].toUpperCase()
              : 'G';
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE8F0FE),
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF1A73E8),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );
    } else {
      final initial = (account.email?.isNotEmpty ?? false)
          ? account.email![0].toUpperCase()
          : 'U';
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: context.colors.primarySoft,
        child: Text(
          initial,
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );
    }

    final String displayName;
    final String displayEmail;
    if (drive.isConnected && account.loggedIn) {
      displayName = drive.displayName ?? account.email!;
      displayEmail = drive.email == account.email
          ? drive.email!
          : '${drive.email} • ${account.email}';
    } else if (drive.isConnected) {
      displayName = drive.displayName ?? drive.email!.split('@').first;
      displayEmail = drive.email!;
    } else {
      displayName = l.account;
      displayEmail = account.email!;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      displayEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (drive.isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCEEAD6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_done_rounded,
                                  size: 12,
                                  color: Color(0xFF137333),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l.googleDriveConnectedBadge,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF137333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (account.loggedIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.dns_rounded,
                                  size: 12,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l.nyawtatServerConnected,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: context.colors.divider),
          _buildStatusAndActions(context, ref, account, drive),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _confirmSignOut(context, ref, account, drive),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.expense,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.signOut),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndActions(
    BuildContext context,
    WidgetRef ref,
    AccountState account,
    GoogleDriveInfo drive,
  ) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    if (account.loggedIn) {
      final String status;
      if (account.syncing) {
        status = l.syncing;
      } else if (account.error != null) {
        status = apiErrorText(l, account.error!);
      } else if (account.lastSyncAt != null) {
        status = l.lastSynced(
          DateFormat(
            'd MMM, HH:mm',
            context.localeTag,
          ).format(account.lastSyncAt!),
        );
      } else {
        status = l.neverSynced;
      }

      return Row(
        children: [
          Icon(
            account.error != null
                ? Icons.cloud_off_outlined
                : Icons.cloud_done_outlined,
            color: account.error != null
                ? context.colors.expense
                : context.colors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: t.bodySmall?.copyWith(
                color: account.error != null
                    ? context.colors.expense
                    : context.colors.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          account.error == ApiError.sessionExpired
              ? OutlinedButton(
                  onPressed: () => SignInScreen.open(context),
                  child: Text(l.signIn),
                )
              : OutlinedButton(
                  onPressed: account.syncing
                      ? null
                      : () => _syncNow(context, ref),
                  child: Text(l.syncNow),
                ),
        ],
      );
    }

    // Hanya Google Drive yang terhubung
    final status = drive.lastBackupTime != null
        ? l.googleDriveLastBackup(
            DateFormat(
              'd MMM, HH:mm',
              context.localeTag,
            ).format(drive.lastBackupTime!),
          )
        : l.googleDriveNever;

    return Row(
      children: [
        Icon(
          Icons.cloud_done_outlined,
          color: context.colors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status,
            style: t.bodySmall?.copyWith(color: context.colors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: drive.isUploading
              ? null
              : () => _backupToGoogleDrive(context, ref),
          child: Text(drive.isUploading ? l.backupNowLoading : l.backupNow),
        ),
      ],
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

  /// Cadangkan cepat ke Google Drive dari kartu akun
  Future<void> _backupToGoogleDrive(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final money = ref.read(moneySnapshotProvider).value;
    final entries = ref.read(journalEntriesProvider).value;

    if (money == null || entries == null) return;

    try {
      final rawJson = await BackupService(ref.read(databaseProvider))
          .exportJson(period: const BackupPeriod.all());
      final now = DateTime.now();
      final stamp = '${toLocalDate(now)}-${hhmm(now).replaceAll(':', '')}';
      final bytes = buildExcelReport(
        l: l,
        money: money,
        entries: entries,
        now: now,
        period: const BackupPeriod.all(),
        rawBackupJson: rawJson,
      );

      final success =
          await ref.read(googleDriveProvider.notifier).backupToDrive(
                bytes: bytes,
                fileName: 'Nyawtat_Cadangan_$stamp.xlsx',
              );

      if (success && context.mounted) {
        showMascotSnackBar(
          context,
          MascotPose.sinkron,
          l.backupNowSuccess,
          aboveDock: false,
        );
      }
    } catch (e) {
      debugPrint('Backup to Drive error: $e');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l.exportFailed)));
      }
    }
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AccountState account,
    GoogleDriveInfo drive,
  ) async {
    final l = context.l10n;

    // Jika keduanya terhubung: tampilkan pilihan keluar
    if (drive.isConnected && account.loggedIn) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l.signOut),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'google'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Putuskan Google Drive Saja'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'server'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Keluar dari Server Saja'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'both'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Keluar dari Semua Akun',
                  style: TextStyle(color: context.colors.expense),
                ),
              ),
            ),
          ],
        ),
      );

      if (choice == 'google' || choice == 'both') {
        await ref.read(googleDriveProvider.notifier).signOut();
      }
      if ((choice == 'server' || choice == 'both') && context.mounted) {
        await ref.read(accountProvider.notifier).signOut();
      }
      return;
    }

    // Jika hanya Google Drive yang terhubung
    if (drive.isConnected) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.googleDriveDisconnect),
          content: const Text(
            'Putuskan akun Google dari Nyawtat? Data lokal di perangkat Anda tetap aman.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.expense,
              ),
              child: Text(l.signOut),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(googleDriveProvider.notifier).signOut();
      }
      return;
    }

    // Jika hanya Server Supabase yang terhubung
    final controller = ref.read(accountProvider.notifier);
    final unsynced = await controller.hasUnsyncedChanges();
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOutConfirm),
        content: Text(
          unsynced ? '${l.signOutBody}\n\n${l.signOutUnsynced}' : l.signOutBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.expense,
            ),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await controller.signOut();
  }
}
