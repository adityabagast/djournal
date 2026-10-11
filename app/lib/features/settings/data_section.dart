import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/backup_service.dart';
import '../../data/excel_report.dart';
import '../../data/import/money_manager_import.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../money/budget_screen.dart';
import '../money/categories_screen.dart';

/// Bagian "Data" di Pengaturan: budget, ekspor, impor, dan impor dari
/// Money Manager.
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    Widget tile(String title, String sub, IconData icon, VoidCallback onTap) =>
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: context.colors.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            sub,
            style: TextStyle(fontSize: 12, color: context.colors.muted),
          ),
          trailing: Icon(Icons.chevron_right, color: context.colors.muted),
        );
    final divider = Divider(
      height: 1,
      indent: 56,
      color: context.colors.divider,
    );

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
            l.manageCategories,
            l.categoriesSub,
            Icons.category_outlined,
            () => CategoriesScreen.open(context),
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
          divider,
          tile(
            l.importMm,
            l.importMmSub,
            Icons.move_to_inbox_outlined,
            () => _importMoneyManager(context, ref),
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
          'nyawtat-${_stamp()}.xlsx',
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
          'nyawtat-backup-${_stamp()}.json',
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

  /// Impor dari Money Manager (.mmbak / .xlsx): baca, tampilkan pratinjau,
  /// baru simpan setelah dikonfirmasi.
  Future<void> _importMoneyManager(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // .mmbak tidak punya MIME type yang dikenal Android, jadi filter
    // ekstensi dilakukan sendiri.
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null || !context.mounted) return;

    final importer = MoneyManagerImporter(ref.read(databaseProvider));
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Text(l.importMmReading),
          ],
        ),
      ),
    );
    MmImportPlan? plan;
    try {
      final data = await readMoneyManagerFile(
        file.name,
        await file.readAsBytes(),
      );
      plan = await importer.plan(data);
    } on MmFormatException catch (e) {
      debugPrint('impor Money Manager ditolak: ${e.message}');
    } catch (e) {
      debugPrint('impor Money Manager gagal dibaca: $e');
    } finally {
      navigator.pop();
    }
    if (plan == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.importMmInvalid)));
      return;
    }
    if (plan.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.importMmNothing)));
      return;
    }
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _MmPreviewDialog(plan: plan!),
    );
    if (ok != true) return;
    final result = await importer.apply(plan);
    messenger.showSnackBar(
      SnackBar(content: Text(l.importMmDone(result.transactions))),
    );
  }
}

/// Ringkasan sebelum impor Money Manager: jumlah, periode, dompet, dan
/// kategori baru.
class _MmPreviewDialog extends StatelessWidget {
  const _MmPreviewDialog({required this.plan});

  final MmImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final muted = t.bodySmall?.copyWith(color: context.colors.muted);
    final date = DateFormat('d MMM y', context.localeTag);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        text,
        style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    return AlertDialog(
      title: Text(l.importMm),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.importMmNew(plan.newTransactions),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              l.importMmBreakdown(
                plan.countOf(MmKind.expense),
                plan.countOf(MmKind.income),
                plan.countOf(MmKind.transfer),
              ),
              style: muted,
            ),
            if (plan.first != null)
              Text(
                l.importMmPeriod(
                  date.format(plan.first!),
                  date.format(plan.last!),
                ),
                style: muted,
              ),
            const SizedBox(height: 8),
            if (plan.alreadyImported > 0)
              Text(l.importMmAlready(plan.alreadyImported), style: muted),
            if (plan.skipped > 0)
              Text(l.importMmSkipped(plan.skipped), style: muted),
            if (plan.adjustmentRows > 0)
              Text(l.importMmAdjust(plan.adjustmentRows), style: muted),
            if (plan.movedTransactions > 0)
              Text(l.importMmMoved(plan.movedTransactions), style: muted),
            heading(l.importMmWallets),
            for (final w in plan.wallets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: w.sourceName),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: context.colors.muted,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: w.existing ? w.name : l.importMmNewWallet,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: w.existing
                              ? context.colors.ink
                              : context.colors.primary,
                        ),
                      ),
                      if (w.archive)
                        TextSpan(
                          text: ' · ${l.importMmArchived}',
                          style: TextStyle(color: context.colors.muted),
                        ),
                    ],
                  ),
                  style: t.bodyMedium,
                ),
              ),
            if (plan.newCategories.isNotEmpty) ...[
              heading(l.importMmNewCategories(plan.newCategories.length)),
              Text(
                plan.newCategories.map((c) => c.name).join(', '),
                style: t.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l.importMmOverlap,
              style: muted?.copyWith(color: context.colors.warning),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.importAction),
        ),
      ],
    );
  }
}
