import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import 'data_section.dart';

/// Pengaturan › Cadangan & pemulihan.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const BackupScreen()));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        context.l10n.settingsBackup,
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
      children: const [DataSection()],
    ),
  );
}
