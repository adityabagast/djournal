import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../providers.dart';
import '../../account/presentation/account_card.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../lock/providers/lock_controller.dart';
import '../../feedback/presentation/feedback_screen.dart';
import '../../update/presentation/version_history_screen.dart';
import 'appearance_section.dart';
import 'settings_pages.dart';

/// Halaman utama Pengaturan: ringkasan akun dan daftar menu.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final lock = ref.watch(lockProvider);
    final drive = ref.watch(googleDriveProvider);
    final info = ref.watch(appVersionProvider).value;
    final theme = switch (ref.watch(themeModeProvider).value) {
      ThemeMode.light => l.themeLight,
      ThemeMode.dark => l.themeDark,
      _ => l.themeSystem,
    };
    final accent = accentName(
      l,
      ref.watch(accentIdProvider).value ?? AccentPresets.sage.id,
    );
    final language = context.localeTag == 'en' ? 'English' : 'Indonesia';

    Widget section(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        AppSpace.xl,
        AppSpace.xs,
        AppSpace.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: t.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.muted,
        ),
      ),
    );

    return SettingsPage(
      title: l.settings,
      children: [
        const AccountCard(),
        section(l.settingsApp),
        SettingsGroup(
          rows: [
            SettingsRow(
              icon: Icons.palette_outlined,
              title: l.settingsAppearance,
              subtitle: '$theme · $accent · $language',
              onTap: () => AppearancePage.open(context),
            ),
            SettingsRow(
              icon: Icons.lock_outline,
              title: l.security,
              subtitle: !lock.pinEnabled
                  ? l.settingsPinOff
                  : lock.biometricEnabled
                  ? l.settingsPinBioOn
                  : l.settingsPinOn,
              onTap: () => SecurityPage.open(context),
            ),
          ],
        ),
        section(l.data),
        SettingsGroup(
          rows: [
            SettingsRow(
              icon: Icons.account_balance_wallet_outlined,
              title: l.navMoney,
              subtitle: l.settingsFinanceSub,
              onTap: () => FinancePage.open(context),
            ),
            SettingsRow(
              icon: Icons.cloud_sync_outlined,
              title: l.settingsBackup,
              subtitle: drive.isConnected
                  ? l.settingsBackupDriveSub
                  : l.settingsBackupLocalSub,
              onTap: () => BackupScreen.open(context),
            ),
          ],
        ),
        section(l.aboutTitle),
        SettingsGroup(
          rows: [
            SettingsRow(
              icon: Icons.system_update_outlined,
              title: l.settingsVersion,
              subtitle: info == null
                  ? 'Nyawtat'
                  : l.aboutVersion(info.version, info.buildNumber),
              onTap: () => VersionPage.open(context),
            ),
            SettingsRow(
              icon: Icons.chat_bubble_outline,
              title: l.fbTitle,
              subtitle: l.fbSub,
              onTap: () => FeedbackScreen.open(context),
            ),
            SettingsRow(
              icon: Icons.history,
              title: l.aboutReleases,
              subtitle: l.aboutReleasesSub,
              onTap: () => VersionHistoryScreen.open(context),
            ),
          ],
        ),
      ],
    );
  }
}
