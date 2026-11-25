import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../backup/data/google_drive_service.dart';
import '../data/backend.dart';
import '../providers/account_controller.dart';
import 'account_screen.dart';
import 'sign_in_screen.dart';

/// Status satu layanan dalam satu kalimat. [ok] false = perlu perhatian.
typedef ServiceStatus = ({String text, bool ok});

String _time(BuildContext context, DateTime at) =>
    DateFormat('d MMM, HH:mm', context.localeTag).format(at);

ServiceStatus driveStatus(
  BuildContext context,
  AppLocalizations l,
  GoogleDriveInfo drive,
) {
  if (!drive.isConnected) return (text: l.driveNotConnected, ok: false);
  if (drive.isUploading) return (text: l.backupNowLoading, ok: true);
  final last = drive.lastBackupTime;
  return (
    text: last == null
        ? l.googleDriveNever
        : l.googleDriveLastBackup(_time(context, last)),
    ok: true,
  );
}

ServiceStatus serverStatus(
  BuildContext context,
  AppLocalizations l,
  AccountState account,
) {
  if (!account.loggedIn) return (text: l.serverNotSignedIn, ok: false);
  if (account.syncing) return (text: l.syncing, ok: true);
  final error = account.error;
  if (error != null) return (text: apiErrorText(l, error), ok: false);
  final last = account.lastSyncAt;
  return (
    text: last == null
        ? l.neverSynced
        : l.serverAutoSynced(_time(context, last)),
    ok: true,
  );
}

/// Perlu login (lagi) supaya sync jalan.
bool needsServerLogin(AccountState account) =>
    !account.loggedIn || account.error == ApiError.sessionExpired;

/// Ringkasan akun di halaman utama Pengaturan. Keluar dan pengaturan akun
/// lainnya ada di [AccountScreen].
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final account = ref.watch(accountProvider);
    final drive = ref.watch(googleDriveProvider);

    if (account.loading) {
      return const AppCard(child: LinearProgressIndicator());
    }

    final guest = !account.loggedIn && !drive.isConnected;
    final emails = {?drive.email, ?account.email};
    final String name;
    if (guest) {
      name = l.guestMode;
    } else if (drive.isConnected) {
      name = drive.displayName ?? drive.email!.split('@').first;
    } else {
      name = l.account;
    }
    final initial = drive.isConnected ? name : account.email ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => AccountScreen.open(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: c.primarySoft,
                  child: initial.isEmpty
                      ? Icon(Icons.person_outline, color: c.primary)
                      : Text(
                          initial[0].toUpperCase(),
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.heading,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.title,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        guest ? l.guestModePrompt : emails.join(' • '),
                        maxLines: guest ? null : 1,
                        overflow: guest ? null : TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.faint),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          _StatusLine(driveStatus(context, l, drive)),
          if (backendConfigured) ...[
            const SizedBox(height: AppSpace.sm),
            _StatusLine(serverStatus(context, l, account)),
            if (needsServerLogin(account)) ...[
              const SizedBox(height: AppSpace.md),
              FilledButton(
                onPressed: () => SignInScreen.open(context),
                child: Text(l.serverSignInTitle),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.status);

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          status.ok ? Icons.check : Icons.error_outline,
          size: 16,
          color: status.ok ? c.primary : c.warning,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            status.text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
              color: status.ok ? c.muted : c.warning,
            ),
          ),
        ),
      ],
    );
  }
}
