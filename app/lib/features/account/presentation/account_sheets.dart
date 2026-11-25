import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/common.dart';

/// Konfirmasi memutus Google Drive. Data dan login server tidak berubah.
class DriveDisconnectSheet extends StatelessWidget {
  const DriveDisconnectSheet({super.key});

  static Future<bool?> show(BuildContext context) => showAppSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const DriveDisconnectSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          _SheetTitle(l.disconnectDriveConfirm),
          const SizedBox(height: AppSpace.sm),
          Text(
            l.disconnectDriveBody,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.stayConnected),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            style: OutlinedButton.styleFrom(foregroundColor: c.expense),
            child: Text(l.disconnect),
          ),
        ],
      ),
    );
  }
}

enum ServerSignOutAction { backup, signOut }

/// Konfirmasi keluar dari server: data di perangkat dihapus, jadi tombolnya
/// baru aktif setelah persetujuan dicentang.
class ServerSignOutSheet extends StatefulWidget {
  const ServerSignOutSheet({super.key, required this.unsynced});

  /// Ada perubahan yang belum terkirim ke server.
  final bool unsynced;

  static Future<ServerSignOutAction?> show(
    BuildContext context, {
    required bool unsynced,
  }) => showAppSheet<ServerSignOutAction>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ServerSignOutSheet(unsynced: unsynced),
  );

  @override
  State<ServerSignOutSheet> createState() => _ServerSignOutSheetState();
}

class _ServerSignOutSheetState extends State<ServerSignOutSheet> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          _SheetTitle(l.signOutServerConfirm),
          const SizedBox(height: AppSpace.sm),
          Text(l.signOutBody, style: t.bodyMedium?.copyWith(color: c.muted)),
          const SizedBox(height: AppSpace.md),
          AccountNote(
            icon: Icons.error_outline,
            text: widget.unsynced
                ? '${l.signOutLocalOnly}\n\n${l.signOutUnsynced}'
                : l.signOutLocalOnly,
            warning: true,
          ),
          const SizedBox(height: AppSpace.md),
          OutlinedButton(
            onPressed: () =>
                Navigator.pop(context, ServerSignOutAction.backup),
            child: Text(l.backupFirst),
          ),
          CheckboxListTile(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(l.signOutAck, style: t.bodyMedium),
          ),
          FilledButton(
            onPressed: _agreed
                ? () => Navigator.pop(context, ServerSignOutAction.signOut)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: c.expense,
              foregroundColor: c.surface,
            ),
            child: Text(l.signOutAndDelete),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }
}

/// Catatan berlatar lembut, dipakai di sheet keluar dan layar masuk.
class AccountNote extends StatelessWidget {
  const AccountNote({
    super.key,
    required this.icon,
    required this.text,
    this.warning = false,
  });

  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: warning ? c.warnSoft : c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: warning ? c.warning : c.primary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}
