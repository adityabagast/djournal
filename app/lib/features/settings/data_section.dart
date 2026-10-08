import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/backup_service.dart';
import '../../data/excel_report.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../money/budget_screen.dart';

/// Bagian "Data" di Pengaturan: budget, ekspor, dan impor.
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    Widget tile(String title, String sub, IconData icon, VoidCallback onTap) =>
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            sub,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        );
    const divider = Divider(height: 1, indent: 56, color: AppColors.divider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          tile(
            l.budget,
            l.budgetSubtitle,
            Icons.pie_chart_outline,
            () => BudgetScreen.open(context),
          ),
          divider,
          tile(
            l.exportExcel,
            l.exportExcelSub,
            Icons.table_chart_outlined,
            () => _exportExcel(context, ref),
          ),
          divider,
          tile(
            l.exportBackup,
            l.exportBackupSub,
            Icons.backup_outlined,
            () => _exportJson(context, ref),
          ),
          divider,
          tile(
            l.importBackup,
            l.importBackupSub,
            Icons.restore_outlined,
            () => _import(context, ref),
          ),
        ],
      ),
    );
  }

  static String _stamp() {
    final now = DateTime.now();
    return '${toLocalDate(now)}-${hhmm(now).replaceAll(':', '')}';
  }

  /// Buka menu share Android/iOS (simpan ke Drive, Files, kirim, dst.).
  /// Di web, file langsung terunduh.
  Future<void> _share(
    BuildContext context,
    List<int> bytes,
    String name,
    String mime,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mime)],
        fileNameOverrides: [name],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      debugPrint('ekspor gagal: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.exportFailed)));
      }
    }
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) =>
      _run(context, () async {
        final money = ref.read(moneySnapshotProvider).value;
        final entries = ref.read(journalEntriesProvider).value;
        if (money == null || entries == null) return;
        final bytes = buildExcelReport(
          l: context.l10n,
          money: money,
          entries: entries,
          now: DateTime.now(),
        );
        await _share(
          context,
          bytes,
          'djournal-${_stamp()}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      });

  Future<void> _exportJson(BuildContext context, WidgetRef ref) =>
      _run(context, () async {
        final json = await BackupService(ref.read(databaseProvider))
            .exportJson();
        if (!context.mounted) return;
        await _share(
          context,
          utf8.encode(json),
          'djournal-backup-${_stamp()}.json',
          'application/json',
        );
      });

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null || !context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.importConfirm(file.name)),
        content: Text(l.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.importAction),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final content = utf8.decode(await file.readAsBytes());
      final result = await BackupService(ref.read(databaseProvider))
          .importJson(content);
      messenger.showSnackBar(
        SnackBar(content: Text(l.importDone(result.imported, result.skipped))),
      );
    } on BackupFormatException catch (e) {
      debugPrint('impor ditolak: ${e.message}');
      messenger.showSnackBar(SnackBar(content: Text(l.importInvalid)));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l.importInvalid)));
    }
  }
}
