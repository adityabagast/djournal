import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../providers.dart';
import '../../lock/presentation/security_section.dart';
import '../../money/presentation/budget_screen.dart';
import '../../money/presentation/categories_screen.dart';
import '../../money/presentation/wallets_screen.dart';
import 'about_section.dart';
import 'appearance_section.dart';

/// Kerangka satu halaman di dalam Pengaturan.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.sm,
        AppSpace.xl,
        AppSpace.xxxl,
      ),
      children: children,
    ),
  );
}

/// Pengaturan › Tampilan & bahasa.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AppearancePage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    const titleStyle = TextStyle(fontWeight: FontWeight.w500);
    return SettingsPage(
      title: l.settingsAppearance,
      children: [
        const AppearanceSection(),
        const SizedBox(height: AppSpace.xl),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    Text(l.language, style: titleStyle),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'id', label: Text('Indonesia')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {context.localeTag},
                      onSelectionChanged: (s) => ref
                          .read(settingsRepositoryProvider)
                          .set('language', s.first),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.divider),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                child: Row(
                  children: [
                    Expanded(child: Text(l.currency, style: titleStyle)),
                    Text(l.currencyValue, style: TextStyle(color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pengaturan › Keamanan.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SecurityPage()));

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: context.l10n.security,
    children: const [SecuritySection()],
  );
}

/// Pengaturan › Keuangan: dompet, kategori, budget.
class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FinancePage()));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SettingsPage(
      title: l.navMoney,
      children: [
        SettingsGroup(
          rows: [
            SettingsRow(
              icon: Icons.account_balance_wallet_outlined,
              title: l.manageWallets,
              subtitle: l.manageWalletsSub,
              onTap: () => WalletsScreen.open(context),
            ),
            SettingsRow(
              icon: Icons.category_outlined,
              title: l.manageCategories,
              subtitle: l.categoriesSub,
              onTap: () => CategoriesScreen.open(context),
            ),
            SettingsRow(
              icon: Icons.pie_chart_outline,
              title: l.budget,
              subtitle: l.budgetSubtitle,
              onTap: () => BudgetScreen.open(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pengaturan › Versi & update.
class VersionPage extends StatelessWidget {
  const VersionPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const VersionPage()));

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: context.l10n.settingsVersion,
    children: const [AboutSection(links: false)],
  );
}

/// Beberapa [SettingsRow] dalam satu kartu.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0)
            Divider(height: 1, indent: 56, color: context.colors.divider),
          row,
        ],
      ],
    ),
  );
}

/// Satu menu Pengaturan: ikon, judul, dan ringkasan keadaannya.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSize.bodyLg,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
      ),
      trailing: Icon(Icons.chevron_right, color: c.faint),
    );
  }
}
