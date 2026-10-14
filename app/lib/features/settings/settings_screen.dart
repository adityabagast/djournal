import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../account/account_card.dart';
import 'appearance_section.dart';
import 'data_section.dart';
import 'security_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final lang = context.localeTag;

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: t.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.muted,
          fontSize: 13,
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const AccountCard(),
          const SizedBox(height: 20),
          sectionTitle(l.language),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.language,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(height: 20),
          sectionTitle(l.appearance),
          const AppearanceSection(),
          const SizedBox(height: 20),
          sectionTitle(l.security),
          const SecuritySection(),
          const SizedBox(height: 20),
          sectionTitle(l.data),
          const DataSection(),
          const SizedBox(height: 20),
          Center(
            child: Text(
              l.versionLabel('0.5.0'),
              style: t.bodySmall?.copyWith(color: context.colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
