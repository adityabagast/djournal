import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../../core/theme.dart';
import '../../data/sync/account_controller.dart';
import '../../data/sync/backend.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import 'sign_in_screen.dart';

/// Kartu akun di Pengaturan: ajakan masuk, atau email + status sync.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final account = ref.watch(accountProvider);

    final avatar = Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_outline, color: AppColors.primary),
    );

    if (account.loading) {
      return const AppCard(child: LinearProgressIndicator());
    }

    if (!backendConfigured) {
      return AppCard(
        child: Text(
          l.backendNotConfigured,
          style: t.bodySmall?.copyWith(color: AppColors.muted),
        ),
      );
    }

    if (!account.loggedIn) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.signInPrompt,
                    style: t.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => SignInScreen.open(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(l.signIn),
            ),
          ],
        ),
      );
    }

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

    return AppCard(
      child: Column(
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
                      l.account,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      account.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.divider),
          Row(
            children: [
              Icon(
                account.error != null
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_done_outlined,
                color: account.error != null
                    ? AppColors.expense
                    : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: t.bodySmall?.copyWith(
                    color: account.error != null
                        ? AppColors.expense
                        : AppColors.muted,
                  ),
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
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: account.syncing
                  ? null
                  : () => _confirmSignOut(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.expense,
                padding: EdgeInsets.zero,
              ),
              child: Text(l.signOut),
            ),
          ),
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

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
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
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await controller.signOut();
  }
}
