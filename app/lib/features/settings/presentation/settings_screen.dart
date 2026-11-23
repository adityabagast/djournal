import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../account/presentation/account_card.dart';
import 'about_section.dart';
import 'appearance_section.dart';
import '../../backup/presentation/data_section.dart';
import '../../lock/presentation/security_section.dart';
import '../../../core/tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final lang = context.localeTag;

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.sm),
      child: Text(
        text.toUpperCase(),
        style: t.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.muted,
          fontSize: AppFontSize.body,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.settings,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
        children: [
          const AccountCard(),
          const SizedBox(height: AppSpace.xl),
          sectionTitle(l.language),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
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
                      Text(
                        l.language,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'id', label: Text('Indonesia')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {lang},
                        onSelectionChanged: (s) => ref
                            .read(settingsRepositoryProvider)
                            .set('language', s.first),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.colors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.currency,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        l.currencyValue,
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          sectionTitle(l.appearance),
          const AppearanceSection(),
          const SizedBox(height: AppSpace.xl),
          sectionTitle(l.security),
          const SecuritySection(),
          const SizedBox(height: AppSpace.xl),
          sectionTitle(l.data),
          const DataSection(),
          const SizedBox(height: AppSpace.xl),
          sectionTitle(l.aboutTitle),
          const AboutSection(),
        ],
      ),
    );
  }
}
